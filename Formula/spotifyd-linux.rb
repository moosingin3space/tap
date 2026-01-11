class SpotifydLinux < Formula
  desc "Spotify daemon, optimzed for Linux"
  homepage "https://spotifyd.rs/"
  url "https://github.com/Spotifyd/spotifyd/archive/refs/tags/v0.4.2.tar.gz"
  sha256 "e1dc21f806b205739e508bd567698657a47ca17eecb0f91d9320af5e74b8418a"
  license "GPL-3.0-only"
  head "https://github.com/Spotifyd/spotifyd.git", branch: "master"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    root_url "https://github.com/moosingin3space/homebrew-tap/releases/download/spotifyd-linux-0.4.2"
    sha256 cellar: :any_skip_relocation, arm64_linux:  "31e4ed79daa7b30e1ac53722570a05afa264acae05f377e20d7dd3a9000ed0d5"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "284164de1604b35b0f3d7ce387b4cfdaf08d6245c76ffd74928bab024cca28b7"
  end

  depends_on "pkgconf" => :build
  depends_on "rust" => :build
  depends_on "dbus"
  depends_on "portaudio"

  on_linux do
    depends_on "openssl@3"
    depends_on "pulseaudio"
  end

  conflicts_with "spotifyd", because: "spotifyd-linux is an optimized Linux variant"

  def install
    ENV["COREAUDIO_SDK_PATH"] = MacOS.sdk_path_if_needed if OS.mac?

    pulseaudio_args = ["--features", "pulseaudio_backend"] if OS.linux?

    system "cargo", "install", "--no-default-features",
                               "--features", "portaudio_backend",
                               *pulseaudio_args,
                               *std_cargo_args
  end

  service do
    backend = OS.linux? ? "pulseaudio" : "portaudio"
    run [opt_bin/"spotifyd", "--no-daemon", "--backend", backend]
    keep_alive true
  end

  test do
    args = ["--no-daemon", "--verbose"]
    Open3.popen2e(bin/"spotifyd", *args) do |_, stdout_and_stderr, wait_thread|
      sleep 5
      Process.kill "TERM", wait_thread.pid
      output = stdout_and_stderr.read
      assert_match "Starting zeroconf server to advertise on local network", output
      refute_match "ERROR", output
    end
  end
end
