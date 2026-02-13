#!/bin/sh

# Generate Secrets.plist from Xcode Cloud environment variables.
# In Xcode Cloud, set PWS_API_KEY as a secret environment variable.

cat > "$CI_PRIMARY_REPOSITORY_PATH/weatherlr/Secrets.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>PWS_API_KEY</key>
    <string>${PWS_API_KEY}</string>
</dict>
</plist>
EOF
