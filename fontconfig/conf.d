<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <match target="pattern">
    <test qual="any" name="family">
      <string>monospace</string>
    </test>
    <edit name="family" mode="assign" binding="same">
      <string>Cica</string>
    </edit>
  </match>
  <match target="pattern">
    <test qual="any" name="family">
      <string>Courier New</string>
    </test>
    <edit name="family" mode="assign" binding="same">
      <string>Cica</string>
    </edit>
  </match>
</fontconfig>
