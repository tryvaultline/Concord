"""Package a Concord IPA from a real Signal-iOS Xcode archive.

This script deliberately does not compile a replacement UIKit app and never
creates a placeholder Mach-O binary.  Concord's iOS client must be built from
the vendored Signal-iOS workspace, preserving Signal's production client
architecture and its iOS 26 Liquid Glass implementation.
"""

from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
import zipfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
IOS_ROOT = ROOT / "clients" / "ios"
WORKSPACE = IOS_ROOT / "Signal.xcworkspace"


def run(command: list[str], *, cwd: Path) -> None:
    print("[BUILD]", " ".join(command))
    subprocess.run(command, cwd=cwd, check=True)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--archive-path",
        type=Path,
        default=ROOT / "build" / "Signal.xcarchive",
        help="Output path for the Xcode archive.",
    )
    parser.add_argument(
        "--output-path",
        type=Path,
        default=ROOT / "build" / "Concord.ipa",
        help="Output path for the exported IPA.",
    )
    parser.add_argument(
        "--team-id",
        help="Apple Developer Team ID used for signing.",
    )
    parser.add_argument(
        "--configuration",
        default="Release",
        choices=("Debug", "Release"),
    )
    parser.add_argument(
        "--unsigned",
        action="store_true",
        help="Build an unsigned device IPA for a sideloading tool to sign.",
    )
    args = parser.parse_args()

    if sys.platform != "darwin":
        parser.error("Packaging requires macOS with Xcode; no fallback IPA is produced.")
    if not WORKSPACE.is_dir():
        parser.error(f"Official Signal-iOS workspace is missing: {WORKSPACE}")
    if not args.unsigned and not args.team_id:
        parser.error("--team-id is required unless --unsigned is used.")

    archive_path = args.archive_path.resolve()
    output_path = args.output_path.resolve()
    archive_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    if output_path.exists():
        output_path.unlink()

    if args.unsigned:
        derived_data = ROOT / "build" / "DerivedData"
        if derived_data.exists():
            shutil.rmtree(derived_data)
        run(
            [
                "xcodebuild",
                "-workspace",
                str(WORKSPACE),
                "-scheme",
                "Signal",
                "-configuration",
                args.configuration,
                "-sdk",
                "iphoneos",
                "-derivedDataPath",
                str(derived_data),
                "-quiet",
                "CODE_SIGNING_ALLOWED=NO",
                "build",
            ],
            cwd=IOS_ROOT,
        )
        app_candidates = list((derived_data / "Build" / "Products").glob("*-iphoneos/Signal.app"))
        if len(app_candidates) != 1:
            raise RuntimeError(f"Expected one built Signal.app, found: {app_candidates}")
        app_path = app_candidates[0]
        run(["plutil", "-replace", "CFBundleIdentifier", "-string", "app.concord.ios", str(app_path / "Info.plist")])
        run(["plutil", "-replace", "CFBundleDisplayName", "-string", "Concord", str(app_path / "Info.plist")])
        run(["plutil", "-replace", "CFBundleName", "-string", "Concord", str(app_path / "Info.plist")])
        run(["plutil", "-replace", "CFBundleExecutable", "-string", "Concord", str(app_path / "Info.plist")])
        (app_path / "Signal").rename(app_path / "Concord")
        concord_app_path = app_path.with_name("Concord.app")
        app_path.rename(concord_app_path)
        with zipfile.ZipFile(output_path, "w", zipfile.ZIP_DEFLATED) as ipa:
            for source_path in concord_app_path.rglob("*"):
                ipa.write(source_path, Path("Payload") / source_path.relative_to(concord_app_path.parent))
        print(f"[OK] Unsigned IPA created from Concord: {output_path}")
        return 0

    if archive_path.exists():
        shutil.rmtree(archive_path)

    run(
        [
            "xcodebuild",
            "-workspace",
            str(WORKSPACE),
            "-scheme",
            "Signal",
            "-configuration",
            args.configuration,
            "-sdk",
            "iphoneos",
            "-archivePath",
            str(archive_path),
            f"DEVELOPMENT_TEAM={args.team_id}",
            "archive",
        ],
        cwd=IOS_ROOT,
    )

    export_options = archive_path.parent / "ConcordExportOptions.plist"
    export_options.write_text(
        """<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\"><dict>
    <key>method</key><string>development</string>
    <key>teamID</key><string>{team_id}</string>
    <key>signingStyle</key><string>automatic</string>
</dict></plist>
""".format(team_id=args.team_id),
        encoding="utf-8",
    )
    export_directory = output_path.parent / "ipa-export"
    if export_directory.exists():
        shutil.rmtree(export_directory)
    run(
        [
            "xcodebuild",
            "-exportArchive",
            "-archivePath",
            str(archive_path),
            "-exportOptionsPlist",
            str(export_options),
            "-exportPath",
            str(export_directory),
        ],
        cwd=IOS_ROOT,
    )
    ipa_files = list(export_directory.glob("*.ipa"))
    if len(ipa_files) != 1:
        raise RuntimeError(f"Expected one exported IPA, found: {ipa_files}")
    shutil.move(str(ipa_files[0]), output_path)
    print(f"[OK] Signed IPA created from Signal-iOS: {output_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
