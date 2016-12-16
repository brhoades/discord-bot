***Discord Bot***
**Description**
This is a bot for Discord with fairly ninche features:
  * Voice announcement on user entering/leaving a channel.
  * Slack-like, mobile-compatible random !giphy.
  * GTA tracking support.
  * Mobile URLs to desktop URL conversions.
  * Weather forecasting.

**Requirements**
Install all gems in the Gemfile with bundle.

For voice announcements:
Install your distribution's version of libsodium, ffmpeg, and Perl (for voice announcements). You will need to update submodules
in the repository too.

For GTA access:
Configure the module and install your distribution's PhantomJS.

**Configuration**
Go through configs/ and copy any module.example.json configurations you will want to module.json in the same folder. Modify these
to reflect your desired configuration.
