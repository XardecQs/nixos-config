{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.modulos.home.desktop.audio;
  jsonFormat = pkgs.formats.json { };

  eqBands = [
    {
      type = "Lo-shelf";
      frequency = 31.0;
      gain = 0.0;
      q = 0.7;
    }
    {
      type = "Bell";
      frequency = 62.0;
      gain = 1.0;
      q = 1.0;
    }
    {
      type = "Bell";
      frequency = 125.0;
      gain = 1.5;
      q = 1.0;
    }
    {
      type = "Bell";
      frequency = 250.0;
      gain = -1.0;
      q = 1.0;
    }
    {
      type = "Bell";
      frequency = 500.0;
      gain = -2.0;
      q = 1.0;
    }
    {
      type = "Bell";
      frequency = 1000.0;
      gain = -1.0;
      q = 1.0;
    }
    {
      type = "Bell";
      frequency = 2000.0;
      gain = 1.0;
      q = 1.0;
    }
    {
      type = "Bell";
      frequency = 4000.0;
      gain = 2.0;
      q = 1.0;
    }
    {
      type = "Bell";
      frequency = 8000.0;
      gain = 1.0;
      q = 1.0;
    }
    {
      type = "Hi-shelf";
      frequency = 16000.0;
      gain = 0.0;
      q = 0.7;
    }
  ];

  eqBandAttrs = lib.listToAttrs (
    lib.imap0 (i: band: {
      name = "band${toString i}";
      value = {
        inherit (band)
          type
          frequency
          gain
          q
          ;
        mode = "IIR";
        solo = false;
        mute = false;
        width = 4.0;
      };
    }) eqBands
  );

  inputPreset = {
    input = {
      blocklist = [ ];
      plugins_order = [
        "rnnoise#0"
        "compressor#0"
        "limiter#0"
      ];
      "rnnoise#0" = {
        bypass = false;
        input-gain = 0.0;
        output-gain = 0.0;
        model-name = "";
        enable-vad = false;
        vad-thres = 50.0;
        wet = 0.0;
        release = 20.0;
        use-standard-model = true;
      };
      "compressor#0" = {
        bypass = false;
        input-gain = 0.0;
        output-gain = 0.0;
        threshold = -18.0;
        ratio = 3.0;
        attack = 20.0;
        release = 200.0;
        knee = 6.0;
        makeup = 6.0;
      };
      "limiter#0" = {
        bypass = false;
        input-gain = 0.0;
        output-gain = 0.0;
        threshold = -1.0;
        release = 100.0;
      };
    };
  };

  outputPreset = {
    output = {
      blocklist = [ ];
      plugins_order = [
        "equalizer#0"
        "limiter#0"
      ];
      "equalizer#0" = {
        bypass = false;
        input-gain = 0.0;
        output-gain = 0.0;
        mode = "IIR";
        split-channels = false;
        balance = 0.0;
        num-bands = 10;
        left = eqBandAttrs;
        right = eqBandAttrs;
      };
      "limiter#0" = {
        bypass = false;
        input-gain = 0.0;
        output-gain = 0.0;
        threshold = -1.0;
        release = 100.0;
      };
    };
  };
in
{
  options.modulos.home.desktop.audio = {
    enable = lib.mkEnableOption "procesado de audio global con EasyEffects";

    preset = lib.mkOption {
      type = lib.types.str;
      default = "xardec";
      description = "Nombre del preset de entrada/salida de EasyEffects.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.easyeffects = {
      enable = true;
      inherit (cfg) preset;
    };

    xdg.dataFile = {
      "easyeffects/input/${cfg.preset}.json".source =
        jsonFormat.generate "input-${cfg.preset}.json" inputPreset;
      "easyeffects/output/${cfg.preset}.json".source =
        jsonFormat.generate "output-${cfg.preset}.json" outputPreset;
    };
  };
}
