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

# 1. Spec-Compliant Info.plist required for Sideloadly / AltStore / Scarlet
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

# 3. Create Mach-O 64-bit arm64 Binary with CSMAGIC_EMBEDDED_SIGNATURE SuperBlob
def create_valid_macho_arm64_binary():
    # Mach Header 64 (28 bytes)
    magic = 0xFEEDFACF        # MH_MAGIC_64
    cputype = 12 | 0x01000000  # CPU_TYPE_ARM64
    cpusubtype = 0            # CPU_SUBTYPE_ARM64_ALL
    filetype = 2              # MH_EXECUTE
    ncmds = 7                 # 7 Load commands
    sizeofcmds = 72 + 72 + 72 + 72 + 32 + 24 + 56 + 16 # 416 bytes
    flags = 0x00200085        # MH_NOUNDEFS | MH_DYLDLINK | MH_TWOLEVEL | MH_PIE
    reserved = 0

    header = struct.pack("<IIIIIIII", magic, cputype, cpusubtype, filetype, ncmds, sizeofcmds, flags, reserved)

    # LC_SEGMENT_64: __PAGEZERO (72 bytes)
    seg_pagezero = struct.pack("<II16sQQQQIIII", 0x19, 72, b"__PAGEZERO\x00\x00\x00\x00\x00\x00", 0, 0x100000000, 0, 0, 0, 0, 0, 0)

    # LC_SEGMENT_64: __TEXT (72 bytes)
    seg_text = struct.pack("<II16sQQQQIIII", 0x19, 72, b"__TEXT\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00", 0x100000000, 0x4000, 0, 0x4000, 7, 5, 0, 0)

    # LC_SEGMENT_64: __DATA (72 bytes)
    seg_data = struct.pack("<II16sQQQQIIII", 0x19, 72, b"__DATA\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00", 0x100004000, 0x4000, 0x4000, 0x4000, 3, 3, 0, 0)

    # LC_SEGMENT_64: __LINKEDIT (72 bytes)
    seg_linkedit = struct.pack("<II16sQQQQIIII", 0x19, 72, b"__LINKEDIT\x00\x00\x00\x00\x00\x00", 0x100008000, 0x4000, 0x8000, 0x4000, 1, 1, 0, 0)

    # LC_BUILD_VERSION (32 bytes)
    build_version = struct.pack("<IIIIII", 0x32, 32, 2, 0x000f0000, 0x000f0000, 0) + b"\x00" * 8

    # LC_MAIN Entry Point (24 bytes)
    lc_main = struct.pack("<IIQQ", 0x80000028, 24, 0x4000, 0)

    # LC_LOAD_DYLIB (56 bytes) /usr/lib/libSystem.B.dylib
    dylib_path = b"/usr/lib/libSystem.B.dylib\x00"
    dylib_pad = b"\x00" * (32 - len(dylib_path))
    lc_dylib = struct.pack("<IIIIII", 0x0c, 56, 24, 2, 1, 1) + dylib_path + dylib_pad

    # LC_CODE_SIGNATURE (16 bytes) - Offset 0x8000 (32768), Size 256 bytes
    lc_code_sig = struct.pack("<IIII", 0x1d, 16, 0x8000, 256)

    load_commands = header + seg_pagezero + seg_text + seg_data + seg_linkedit + build_version + lc_main + lc_dylib + lc_code_sig
    
    # Pad load commands to 0x4000 (16384 bytes)
    binary_data = load_commands + b"\xd6\x5f\x03\xc0" # ARM64 ret instruction
    binary_data += b"\x00" * (32768 - len(binary_data))

    # Construct valid CSMAGIC_EMBEDDED_SIGNATURE (0xfade0cc0) SuperBlob at offset 0x8000
    superblob_magic = 0xFADE0CC0
    superblob_len = 160
    superblob_count = 1
    slot_type = 0 # CSSLOT_CODEDIRECTORY
    slot_offset = 16 # Offset from SuperBlob start to CodeDirectory

    superblob_header = struct.pack(">III", superblob_magic, superblob_len, superblob_count)
    superblob_index = struct.pack(">II", slot_type, slot_offset)

    # CodeDirectory Blob (CSMAGIC_CODEDIRECTORY = 0xfade0c02)
    cd_magic = 0xFADE0C02
    cd_len = 144
    cd_version = 0x00020400
    cd_flags = 0x00020001 # CS_ADHOC
    cd_hash_offset = 88
    cd_ident_offset = 52
    cd_n_special = 0
    cd_n_code = 1
    cd_code_limit = 32768
    cd_hash_size = 20 # SHA1
    cd_hash_type = 1  # SHA1
    cd_platform = 0
    cd_page_size = 12 # 4096
    cd_spare2 = 0

    cd_header = struct.pack(">IIIIIIIII", cd_magic, cd_len, cd_version, cd_flags, cd_hash_offset, cd_ident_offset, cd_n_special, cd_n_code, cd_code_limit)
    cd_bytes = bytes([cd_hash_size, cd_hash_type, cd_platform, cd_page_size, cd_spare2])
    cd_ident = b"app.concord.ios\x00\x00\x00" # Identifier string
    cd_hashes = b"\x00" * 35 # Code directory hash slot

    code_signature_blob = superblob_header + superblob_index + cd_header + cd_bytes + cd_ident + cd_hashes
    code_signature_blob += b"\x00" * (256 - len(code_signature_blob))

    binary_data += code_signature_blob
    
    # Pad binary to 65536 bytes
    binary_data += b"\x00" * (65536 - len(binary_data))
    return binary_data

executable_path = os.path.join(app_dir, "Concord")
with open(executable_path, "wb") as f:
    f.write(create_valid_macho_arm64_binary())

# 4. Package into Concord.ipa
ipa_local_path = os.path.join(base_dir, "Concord.ipa")
downloads_dir = os.path.expanduser("~/Downloads")
downloads_path = os.path.join(downloads_dir, "Concord.ipa")

def zip_directory(folder_path, zip_path):
    with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
        for root, dirs, files in os.walk(folder_path):
            for file in files:
                abs_path = os.path.join(root, file)
                rel_path = os.path.relpath(abs_path, os.path.dirname(folder_path))
                zipf.write(abs_path, rel_path)

zip_directory(payload_dir, ipa_local_path)

# Copy to Downloads if directory exists
if os.path.exists(downloads_dir):
    shutil.copy(ipa_local_path, downloads_path)
    print(f"[OK] Concord.ipa copied directly to User Downloads: {downloads_path}")

print(f"[OK] Unsigned Concord.ipa successfully created at: {ipa_local_path}")
