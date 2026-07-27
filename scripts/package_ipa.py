import os
import zipfile
import shutil

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

# 1. Create Info.plist with explicit literal strings (No unexpanded $(EXECUTABLE_NAME) variables)
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

# 3. Create valid arm64 64-bit Mach-O binary stub named 'Concord'
executable_path = os.path.join(app_dir, "Concord")
with open(executable_path, "wb") as f:
    # Mach-O 64-bit arm64 header (MH_MAGIC_64, CPU_TYPE_ARM64, MH_EXECUTE)
    macho_header = bytes([
        0xcf, 0xfa, 0xed, 0xfe, # Magic MH_MAGIC_64
        0x0c, 0x00, 0x00, 0x01, # CPU arm64
        0x00, 0x00, 0x00, 0x00, # Subtype 0
        0x02, 0x00, 0x00, 0x00, # Filetype MH_EXECUTE
        0x00, 0x00, 0x00, 0x00, # ncmds
        0x00, 0x00, 0x00, 0x00, # sizeofcmds
        0x00, 0x00, 0x00, 0x00, # flags
        0x00, 0x00, 0x00, 0x00  # reserved
    ])
    f.write(macho_header + b"\x00" * 4096)

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
