{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  swapDevices = [ {
    device = "/var/lib/swapfile";
    size = 8192; # size in megabytes
  } ];

  environment = {
    shellAliases = {
      start = "sway --unsupported-gpu";
      nixe = "nvim ~/nix-config/configuration.nix";
      nixf = "nvim ~/nix-config/flakes.nix";
      nixb = "sudo nixos-rebuild switch --flake ~/nix-config#roeetnixos";
      # stuck that first sudo in so I can input the password at the start hehe
      nixu = "sudo nix flake update --flake ~/nix-config && sudo nixos-rebuild switch --flake ~/nix-config#roeetnixos";
    };

    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      SUDO_EDITOR = "nvim";
    };
  };

  # ============================================================================
  # System & Boot
  # ============================================================================
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  time.timeZone = "Asia/Jerusalem";
  system.stateVersion = "26.05";

  nixpkgs.config.allowUnfree = true;

  networking = {
    hostName = "roeetnixos";
    networkmanager.enable = true;
  };

  # according to gemini, to handle hardware decoding
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [ nvidia-vaapi-driver ];
  };

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    open = true;
  };

  # Add this so Wayland applications use the driver:
  environment.variables = {
    LIBVA_DRIVER_NAME = "nvidia";
    NVD_BACKEND = "direct";
  };

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  services.blueman.enable = true;

  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
  };

  # for remote access with nautilus
  services.gvfs.enable = true;

  programs.kdeconnect.enable = true;

  programs.gamemode.enable = true;
  programs.gamescope.enable = true;

  environment.systemPackages = with pkgs; [
    vim
    wget
    nautilus
  ];

  # for stupid nuphyio to workk
  services.udev.extraRules = ''
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", TAG+="uaccess"
  '';

  users.users.roeet = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "gamemode" ];
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";

    users.roeet = { pkgs, ... }: {
      home.stateVersion = "26.05";

      xdg.desktopEntries.tidal-hifi = {
        name = "TIDAL Hi-Fi";
        exec = "tidal-hifi --no-sandbox %U";
        terminal = false;
      };

      xdg.mimeApps.enable = true;
      xdg.mimeApps.defaultApplications = {
        "text/html" = "firefox";
        "x-scheme-handler/http" = "firefox";
        "x-scheme-handler/https" = "firefox";
        "x-scheme-handler/about" = "firefox";
        "x-scheme-handler/unknown" = "firefox";
      };

      home.sessionVariables = {
        # Encourage Qt apps to run natively on Wayland instead of XWayland
        QT_QPA_PLATFORM = "wayland";
        BROWSER = "firefox";
      };

      home.packages = with pkgs; [
        tree
        wofi
        tidal-hifi
        grim
        slurp
        wl-clipboard
        fastfetch
        chromium
        wev
        pavucontrol
        prismlauncher
        playerctl
        inputs.bedrock-on-linux.packages.${pkgs.stdenv.hostPlatform.system}.default
        jellyfin-mpv-shim
      ];
      
      programs.firefox = {
        enable = true;

        profiles.roeet = {
          isDefault = true;
          settings = {
            # Enable Dark Theme for UI and Web content
            "ui.systemUsesDarkTheme" = 1;
            "browser.theme.content-theme" = 0;
            "extensions.activeThemeID" = "firefox-compact-dark@mozilla.org";

            "browser.aboutConfig.showWarning" = false;
            "privacy.trackingprotection.enabled" = true;
            "signon.rememberSignons" = false; # Disable built-in password manager (use Bitwarden instead)
          };
        };

        policies = {
          DisablePocket = true;
          DisableTelemetry = true;

          ExtensionSettings = {
            "definer@lumetrium.com" = {
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/lumetrium-definer/latest.xpi";
              installation_mode = "force_installed";
            };

            "uBlock0@raymondhill.net" = {
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
              installation_mode = "force_installed";
            };

            "addon@darkreader.org" = {
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/darkreader/latest.xpi";
              installation_mode = "force_installed";
            };

            "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
              installation_mode = "force_installed";
            };

            "sponsorBlocker@ajay.app" = {
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/sponsorblock/latest.xpi";
              installation_mode = "force_installed";
            };
          };
        };
      };

      programs.foot = {
        enable = true;
        settings = {
          main = {
            term = "foot";
            font = "monospace:size=11";
            pad = "8x8";
          };
          colors-dark = {
            alpha = 1;
          };
        };
      };

      programs.git = {
        enable = true;

        includes = [
            { path = "~/.gitconfig.local"; }
          ];

        settings = {
          init.defaultBranch = "main";
          pull.rebase = true;
          push.autoSetupRemote = true;
        };
      };

      programs.ssh = {
        enable = true;
        
        # Suppresses the default values removal warning
        enableDefaultConfig = false;
        
        # Replaces the deprecated matchBlocks
        settings = {
          "github.com" = {
            HostName = "github.com";
            User = "git";
            IdentityFile = "~/.ssh/id_ed25519";
          };
        };
      };

      programs.mangohud = {
        enable = true;
        enableSessionWide = false;
        settings = {
          full = true;
        };
      };

      programs.neovim = {
        enable = true;
        defaultEditor = true;
        extraPackages = [ pkgs.fribidi ];

        initLua = ''
          local opt = vim.opt

          -- Core settings
          opt.number = true
          opt.tabstop = 4
          opt.shiftwidth = 4
          opt.expandtab = true
          opt.ignorecase = true
          opt.smartcase = true
          opt.autoindent = true
          opt.cursorline = true
          opt.hlsearch = true
          opt.wrap = true

          -- Sway/Wayland clipboard support
          opt.clipboard = "unnamedplus"
        '';
      };

      programs.i3status = {
        enable = true;
        modules = {
          "volume master" = {
            position = 1; # Adjust this to change its position on the bar
            settings = {
              format = "V: %volume";
              format_muted = "V: muted (%volume)";
              device = "default";
              mixer = "Master";
              mixer_idx = 0;
            };
          };
        };
      };

      wayland.windowManager.sway = {
        enable = true;

        # enable tearing
        extraConfig = ''
          for_window [class=".*"] tearing enable
        '';

        config = {
	      modifier = "Mod4";
          terminal = "foot";
          left = "h";
          down = "j";
          up = "k";
          right = "l";

          # Monitor outputs configuration using the port names directly
          output = {
            "DP-3" = {
              mode = "3440x1440@180Hz";
              position = "1080,240";
              adaptive_sync = "on";
              render_bit_depth = "10";
              # hdr = "on";
            };

            "HDMI-A-1" = {
              mode = "1920x1080@144Hz";
              position = "0,0";
              transform = "270";
            };
          };

          keybindings = lib.mkOptionDefault {
            # Full screen to file: Super + P
            "Mod4+p" = "exec grim ~/Pictures/$(date +'%Y-%m-%d+%H:%M:%S').png";
            # Region to file: Super + Shift + P
            "Mod4+Shift+p" = "exec grim -g \"$(slurp)\" ~/Pictures/$(date +'%Y-%m-%d+%H:%M:%S').png";
            # Region to clipboard (like Windows/macOS): Super + Shift + S
            "Mod4+Shift+s" = "exec grim -g \"$(slurp)\" - | wl-copy";

            "XF86AudioMute" = "exec pactl set-sink-mute @DEFAULT_SINK@ toggle";
            "XF86AudioLowerVolume" = "exec pactl set-sink-volume @DEFAULT_SINK@ -5%";
            "XF86AudioRaiseVolume" = "exec pactl set-sink-volume @DEFAULT_SINK@ +5%";
            "XF86AudioMicMute" = "exec pactl set-source-mute @DEFAULT_SOURCE@ toggle";

            "XF86AudioPlay" = "exec playerctl --player=tidal-hifi play-pause";
            "XF86AudioNext" = "exec playerctl --player=tidal-hifi next";
            "XF86AudioPrev" = "exec playerctl --player=tidal-hifi previous";
            "XF86Tools" = "exec tidal-hifi";

            "Mod4+Ctrl+Shift+1" = "input type:keyboard xkb_switch_layout 0";
            "Mod4+Ctrl+Shift+2" = "input type:keyboard xkb_switch_layout 1";
            "Mod4+Ctrl+Shift+3" = "input type:keyboard xkb_switch_layout 2";
          };

          input = {
            "type:keyboard" = {
              xkb_layout = "us,il,epo";
              xkb_options = "grp:alt_shift_toggle"; # Toggles layout with Alt+Shift
            };
          };

          # Assign workspaces to outputs
	      workspaceOutputAssign = [
            { workspace = "1"; output = "DP-3"; }
            { workspace = "2"; output = "DP-3"; }
            { workspace = "3"; output = "DP-3"; }
            { workspace = "4"; output = "DP-3"; }
            { workspace = "5"; output = "DP-3"; }
            { workspace = "6"; output = "HDMI-A-1"; }
            { workspace = "7"; output = "HDMI-A-1"; }
            { workspace = "8"; output = "HDMI-A-1"; }
            { workspace = "9"; output = "HDMI-A-1"; }
            { workspace = "10"; output = "HDMI-A-1"; }
          ];
        };
      };
    };
  };
}
