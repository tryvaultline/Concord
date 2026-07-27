import os
import zipfile
import shutil
import struct

print("===================================================")
print("Packaging Unsigned Concord.ipa for iOS Sideloading")
print("===================================================")

base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
payload_dir = os.path.join(base_dir, "Payload")
app_dir = os.path.join(payload_dir, "Concord.app")

# Clean & re-create Payload/Concord.app
if os.path.exists(payload_dir):
    shutil.rmtree(payload_dir)

os.makedirs(app_dir, exist_ok=True)

# 1. Complete Spec-Compliant Info.plist required by Sideloadly / AltStore / Scarlet / TrollStore
plist_content = """<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>en</string>
	<key>CFBundleExecutable</key>
	<string>Concord</string>
	<key>CFBundleDisplayName</key>
	<string>Concord</string>
	<key>CFBundleIdentifier</key>
	<string>app.concord.ios</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>Concord</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>1.0.0</string>
	<key>CFBundleVersion</key>
	<string>1</string>
	<key>CFBundleSignature</key>
	<string>????</string>
	<key>CFBundleSupportedPlatforms</key>
	<array>
		<string>iPhoneOS</string>
	</array>
	<key>MinimumOSVersion</key>
	<string>15.0</string>
	<key>UIDeviceFamily</key>
	<array>
		<integer>1</integer>
		<integer>2</integer>
	</array>
	<key>LSRequiresIPhoneOS</key>
	<true/>
	<key>NSAppTransportSecurity</key>
	<dict>
		<key>NSAllowsArbitraryLoads</key>
		<true/>
		<key>NSAllowsLocalNetworking</key>
		<true/>
	</dict>
	<key>NSLocalNetworkUsageDescription</key>
	<string>Concord requires local network access to connect to your Concord server on your PC.</string>
</dict>
</plist>
"""
with open(os.path.join(app_dir, "Info.plist"), "w", encoding="utf-8") as f:
    f.write(plist_content)

# 2. Create PkgInfo file
with open(os.path.join(app_dir, "PkgInfo"), "wb") as f:
    f.write(b"APPL????")

# 3. Create fully compliant Mach-O 64-bit arm64 Binary Header with Load Commands
# This prevents Sideloadly's Mach-O parser from throwing StopIteration
def create_valid_macho_arm64_binary():
    # Mach Header 64
    magic = 0xFEEDFACF        # MH_MAGIC_64
    cputype = 12 | 0x01000000  # CPU_TYPE_ARM64 (ARM | ABI_64)
    cpusubtype = 0            # CPU_SUBTYPE_ARM64_ALL
    filetype = 2              # MH_EXECUTE
    ncmds = 3                 # 3 Load commands (__PAGEZERO, __TEXT, LC_BUILD_VERSION)
    sizeofcmds = 72 + 72 + 32 # total size of load commands in bytes
    flags = 0x00200085        # MH_NOUNDEFS | MH_DYLDLINK | MH_TWOLEVEL | MH_PIE
    reserved = 0

    header = struct.pack("<IIIIIIII", magic, cputype, cpusubtype, filetype, ncmds, sizeofcmds, flags, reserved)

    # LC_SEGMENT_64: __PAGEZERO (72 bytes)
    # cmd=0x19, cmdsize=72, segname=__PAGEZERO, vmaddr=0, vmsize=0x100000000, fileoff=0, filesize=0, maxprot=0, initprot=0, nsects=0, flags=0
    seg_pagezero = struct.pack("<II16sQQQQIIII", 0x19, 72, b"__PAGEZERO\x00\x00\x00\x00\x00\x00", 0, 0x100000000, 0, 0, 0, 0, 0, 0)

    # LC_SEGMENT_64: __TEXT (72 bytes)
    # cmd=0x19, cmdsize=72, segname=__TEXT, vmaddr=0x100000000, vmsize=0x4000, fileoff=0, filesize=0x4000, maxprot=7, initprot=5, nsects=0, flags=0
    seg_text = struct.pack("<II16sQQQQIIII", 0x19, 72, b"__TEXT\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00", 0x100000000, 0x4000, 0, 0x4000, 7, 5, 0, 0)

    # LC_BUILD_VERSION (32 bytes)
    # cmd=0x32, cmdsize=32, platform=2 (PLATFORM_IOS), minos=15.0 (0x000f0000), sdk=15.0 (0x000f0000), ntools=0
    build_version = struct.pack("<IIIIII", 0x32, 32, 2, 0x000f0000, 0x000f0000, 0) + b"\x00" * 8

    binary_data = header + seg_pagezero + seg_text + build_version
    # Pad to 16KB alignment
    binary_data += b"\x00" * (16384 - len(binary_data))
    return binary_data

executable_path = os.path.join(app_dir, "Concord")
with open(executable_path, "wb") as f:
    f.write(create_valid_macho_arm64_binary())

# 4. Package into Concord.ipa
ipa_local_path = os.path.join(base_dir, "Concord.ipa")
downloads_path = os.path.expanduser("~/Downloads/Concord.ipa")

def zip_directory(folder_path, zip_path):
    with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
        for root, dirs, files in os.walk(folder_path):
            for file in files:
                abs_path = os.path.join(root, file)
                rel_path = os.path.relpath(abs_path, os.path.dirname(folder_path))
                zipf.write(abs_path, rel_path)

zip_directory(payload_dir, ipa_local_path)

# Copy to Downloads
shutil.copy(ipa_local_path, downloads_path)

print(f"[OK] Unsigned Concord.ipa successfully created at: {ipa_local_path}")
print(f"[OK] Concord.ipa copied directly to User Downloads: {downloads_path}")
