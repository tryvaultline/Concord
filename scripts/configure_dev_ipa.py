"""Configure an unsigned Concord IPA for one private-LAN development server.

This is intentionally limited to RFC1918 IPv4 hosts and marks the IPA as a
development-only insecure-local-auth build. Production builds must use HTTPS.
"""

from __future__ import annotations

import argparse
import ipaddress
import plistlib
import tempfile
import zipfile
from pathlib import Path
from urllib.parse import urlparse


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("ipa", type=Path)
    parser.add_argument("--auth-base-url", required=True)
    args = parser.parse_args()

    url = urlparse(args.auth_base_url)
    if url.scheme != "http" or not url.hostname:
        parser.error("--auth-base-url must be an http URL for a private local development host")
    try:
        address = ipaddress.ip_address(url.hostname)
    except ValueError as error:
        parser.error(f"The development host must be an IPv4 address: {error}")
    if address.version != 4 or not address.is_private:
        parser.error("The development host must be a private RFC1918 IPv4 address")

    ipa_path = args.ipa.resolve()
    plist_name = "Payload/Concord.app/Info.plist"
    with zipfile.ZipFile(ipa_path, "r") as source:
        try:
            info = plistlib.loads(source.read(plist_name))
        except KeyError as error:
            raise RuntimeError(f"Missing {plist_name}") from error
        info["ConcordAuthBaseURL"] = args.auth_base_url.rstrip("/")
        info["ConcordAllowInsecureLocalAuth"] = True
        ats = info.setdefault("NSAppTransportSecurity", {})
        domains = ats.setdefault("NSExceptionDomains", {})
        domains[str(address)] = {
            "NSExceptionAllowsInsecureHTTPLoads": True,
            "NSIncludesSubdomains": False,
        }
        replacement = plistlib.dumps(info, fmt=plistlib.FMT_BINARY, sort_keys=False)
        archive_contents = [
            (item, replacement if item.filename == plist_name else source.read(item.filename))
            for item in source.infolist()
        ]

    with tempfile.NamedTemporaryFile(dir=ipa_path.parent, suffix=".ipa", delete=False) as temporary:
        temporary_path = Path(temporary.name)
    try:
        with zipfile.ZipFile(temporary_path, "w", zipfile.ZIP_DEFLATED) as destination:
            for item, contents in archive_contents:
                destination.writestr(item, contents)
        temporary_path.replace(ipa_path)
    finally:
        temporary_path.unlink(missing_ok=True)
    print(f"[OK] Configured {ipa_path} for local Concord Auth at {args.auth_base_url}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
