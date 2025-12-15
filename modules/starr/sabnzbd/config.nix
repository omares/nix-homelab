{
  lib,
  pkgs,
  config,
  mares,
  ...
}:
let
  cfg = config.mares.starr;

  scriptsDir = pkgs.linkFarm "sabnzbdScript" [
    {
      name = "clean.py";
      path = import ./clean_py.nix { inherit lib pkgs; };
    }
    {
      name = "replace_for.py";
      path = import ./replace_for.nix { inherit lib pkgs; };
    }
  ];

  settings = {
    globalSection = {
      __version__ = 19;
      __encoding__ = "utf-8";
    };
    sections = {
      misc = {
        helpful_warnings = 1;
        queue_complete = "";
        queue_complete_pers = 0;
        bandwidth_perc = 80;
        refresh_rate = 1;
        interface_settings = "";
        queue_limit = 20;
        config_lock = 0;
        fixed_ports = 1;
        notified_new_skin = 2;
        direct_unpack_tested = 0;
        sorters_converted = 1;
        check_new_rel = 1;
        auto_browser = 0;
        language = "en";
        enable_https_verification = 1;
        host = cfg.sabnzbd.bindAddress;
        port = 8080;
        https_port = "";
        username = config.sops.placeholder.sabnzbd-username;
        password = config.sops.placeholder.sabnzbd-password;
        bandwidth_max = "14M";
        cache_limit = "978.8 M";
        web_dir = "Glitter";
        web_color = "Auto";
        https_cert = "server.cert";
        https_key = "server.key";
        https_chain = "";
        enable_https = 0;
        inet_exposure = 0;
        api_key = config.sops.placeholder.sabnzbd-api_key;
        nzb_key = config.sops.placeholder.sabnzbd-nzb_key;
        socks5_proxy_url = "";
        permissions = "";
        download_dir = "/mnt/media/usenet/incomplete";
        download_free = "";
        complete_dir = "/mnt/media/usenet/complete";
        complete_free = "";
        fulldisk_autoresume = 0;
        script_dir = "${scriptsDir}";
        nzb_backup_dir = "nzb-backup";
        admin_dir = "admin";
        backup_dir = "";
        dirscan_dir = "";
        dirscan_speed = 5;
        password_file = "";
        log_dir = "logs";
        max_art_tries = 3;
        top_only = 0;
        sfv_check = 1;
        script_can_fail = 0;
        enable_recursive = 1;
        flat_unpack = 1;
        par_option = "";
        pre_check = 0;
        nice = "";
        win_process_prio = 3;
        ionice = "";
        fail_hopeless_jobs = 1;
        fast_fail = 1;
        auto_disconnect = 1;
        pre_script = "clean.py";
        end_queue_script = "None";
        no_dupes = 1;
        no_series_dupes = 0;
        no_smart_dupes = 1;
        dupes_propercheck = 1;
        pause_on_pwrar = 1;
        ignore_samples = 0;
        deobfuscate_final_filenames = 1;
        auto_sort = "";
        direct_unpack = 1;
        propagation_delay = 0;
        folder_rename = 1;
        replace_spaces = 0;
        replace_underscores = 0;
        replace_dots = 0;
        safe_postproc = 1;
        pause_on_post_processing = 0;
        enable_all_par = 0;
        sanitize_safe = 0;
        cleanup_list = ",";
        unwanted_extensions = "ade, adp, app, application, appref-ms, asp, aspx, asx, bas, bat, bgi, cab, cer, chm, cmd, cnt, com, cpl, crt, csh, der, diagcab, exe, fxp, gadget, grp, hlp, hpj, hta, htc, inf, ins, iso, isp, its, jar, jnlp, js, jse, ksh, lnk, mad, maf, mag, mam, maq, mar, mas, mat, mau, mav, maw, mcf, mda, mdb, mde, mdt, mdw, mdz, msc, msh, msh1, msh2, mshxml, msh1xml, msh2xml, msi, msp, mst, msu, ops, osd, pcd, pif, pl, plg, prf, prg, printerexport, ps1, ps1xml, ps2, ps2xml, psc1, psc2, psd1, psdm1, pst, py, pyc, pyo, pyw, pyz, pyzw, reg, scf, scr, sct, shb, shs, theme, tmp, url, vb, vbe, vbp, vbs, vhd, vhdx, vsmacros, vsw, webpnp, website, ws, wsc, wsf, wsh, xbap, xll, xnk";
        action_on_unwanted_extensions = 2;
        unwanted_extensions_mode = 0;
        new_nzb_on_failure = 0;
        history_retention = "";
        history_retention_option = "all";
        history_retention_number = 1;
        quota_size = "";
        quota_day = "";
        quota_resume = 0;
        quota_period = "m";
        enable_tv_sorting = 0;
        tv_sort_string = "";
        tv_categories = "tv,";
        enable_movie_sorting = 0;
        movie_sort_string = "";
        movie_sort_extra = "-cd%1";
        movie_categories = "movies,";
        enable_date_sorting = 0;
        date_sort_string = "";
        date_categories = "tv,";
        schedlines = "1 0 1 1234567 speedlimit 0, 1 0 7 1234567 speedlimit 3m";
        rss_rate = 60;
        ampm = 0;
        start_paused = 0;
        preserve_paused_state = 0;
        enable_par_cleanup = 1;
        process_unpacked_par2 = 1;
        enable_multipar = 1;
        enable_unrar = 1;
        enable_7zip = 1;
        enable_filejoin = 1;
        enable_tsjoin = 1;
        overwrite_files = 0;
        ignore_unrar_dates = 0;
        backup_for_duplicates = 0;
        empty_postproc = 0;
        wait_for_dfolder = 0;
        rss_filenames = 0;
        api_logging = 1;
        html_login = 1;
        disable_archive = 0;
        warn_dupl_jobs = 0;
        keep_awake = 1;
        tray_icon = 1;
        allow_incomplete_nzb = 0;
        enable_broadcast = 1;
        ipv6_hosting = 0;
        ipv6_staging = 0;
        api_warnings = 1;
        no_penalties = 0;
        x_frame_options = 1;
        allow_old_ssl_tls = 0;
        enable_season_sorting = 1;
        verify_xff_header = 0;
        rss_odd_titles = "nzbindex.nl/, nzbindex.com/, nzbclub.com/";
        quick_check_ext_ignore = "nfo, sfv, srr";
        req_completion_rate = 100.2;
        selftest_host = "self-test.sabnzbd.org";
        movie_rename_limit = "100M";
        episode_rename_limit = "20M";
        size_limit = 0;
        direct_unpack_threads = 3;
        history_limit = 10;
        wait_ext_drive = 5;
        max_foldername_length = 246;
        nomedia_marker = "";
        ipv6_servers = 1;
        url_base = "/sabnzbd";
        host_whitelist = "nixos,";
        local_ranges = ",";
        max_url_retries = 10;
        downloader_sleep_time = 10;
        receive_threads = 2;
        switchinterval = 5.0e-3;
        ssdp_broadcast_interval = 15;
        ext_rename_ignore = ",";
        email_server = "";
        email_to = ",";
        email_from = "";
        email_account = "";
        email_pwd = "";
        email_endjob = 0;
        email_full = 0;
        email_dir = "";
        email_rss = 0;
        email_cats = "*,";
        config_conversion_version = 4;
        disable_par2cmdline = 0;
      };
      logging = {
        log_level = 1;
        max_log_size = 5242880;
        log_backups = 5;
      };
      ncenter = {
        ncenter_enable = 0;
        ncenter_cats = "*,";
        ncenter_prio_startup = 0;
        ncenter_prio_download = 0;
        ncenter_prio_pause_resume = 0;
        ncenter_prio_pp = 0;
        ncenter_prio_complete = 1;
        ncenter_prio_failed = 1;
        ncenter_prio_disk_full = 1;
        ncenter_prio_new_login = 0;
        ncenter_prio_warning = 0;
        ncenter_prio_error = 0;
        ncenter_prio_queue_done = 0;
        ncenter_prio_other = 1;
      };
      acenter = {
        acenter_enable = 0;
        acenter_cats = "*,";
        acenter_prio_startup = 0;
        acenter_prio_download = 0;
        acenter_prio_pause_resume = 0;
        acenter_prio_pp = 0;
        acenter_prio_complete = 1;
        acenter_prio_failed = 1;
        acenter_prio_disk_full = 1;
        acenter_prio_new_login = 0;
        acenter_prio_warning = 0;
        acenter_prio_error = 0;
        acenter_prio_queue_done = 0;
        acenter_prio_other = 1;
      };
      ntfosd = {
        ntfosd_enable = 1;
        ntfosd_cats = "*,";
        ntfosd_prio_startup = 0;
        ntfosd_prio_download = 0;
        ntfosd_prio_pause_resume = 0;
        ntfosd_prio_pp = 0;
        ntfosd_prio_complete = 1;
        ntfosd_prio_failed = 1;
        ntfosd_prio_disk_full = 1;
        ntfosd_prio_new_login = 0;
        ntfosd_prio_warning = 0;
        ntfosd_prio_error = 0;
        ntfosd_prio_queue_done = 0;
        ntfosd_prio_other = 1;
      };
      prowl = {
        prowl_enable = 0;
        prowl_cats = "*,";
        prowl_apikey = "";
        prowl_prio_startup = -3;
        prowl_prio_download = -3;
        prowl_prio_pause_resume = -3;
        prowl_prio_pp = -3;
        prowl_prio_complete = 0;
        prowl_prio_failed = 1;
        prowl_prio_disk_full = 1;
        prowl_prio_new_login = -3;
        prowl_prio_warning = -3;
        prowl_prio_error = -3;
        prowl_prio_queue_done = -3;
        prowl_prio_other = 0;
      };
      pushover = {
        pushover_token = "";
        pushover_userkey = "";
        pushover_device = "";
        pushover_emergency_expire = 3600;
        pushover_emergency_retry = 60;
        pushover_enable = 0;
        pushover_cats = "*,";
        pushover_prio_startup = -3;
        pushover_prio_download = -2;
        pushover_prio_pause_resume = -2;
        pushover_prio_pp = -3;
        pushover_prio_complete = -1;
        pushover_prio_failed = -1;
        pushover_prio_disk_full = 1;
        pushover_prio_new_login = -3;
        pushover_prio_warning = 1;
        pushover_prio_error = 1;
        pushover_prio_queue_done = -3;
        pushover_prio_other = -1;
      };
      pushbullet = {
        pushbullet_enable = 0;
        pushbullet_cats = "*,";
        pushbullet_apikey = "";
        pushbullet_device = "";
        pushbullet_prio_startup = 0;
        pushbullet_prio_download = 0;
        pushbullet_prio_pause_resume = 0;
        pushbullet_prio_pp = 0;
        pushbullet_prio_complete = 1;
        pushbullet_prio_failed = 1;
        pushbullet_prio_disk_full = 1;
        pushbullet_prio_new_login = 0;
        pushbullet_prio_warning = 0;
        pushbullet_prio_error = 0;
        pushbullet_prio_queue_done = 0;
        pushbullet_prio_other = 1;
      };
      apprise = {
        apprise_enable = 0;
        apprise_cats = "*,";
        apprise_urls = "";
        apprise_target_startup = "";
        apprise_target_startup_enable = 0;
        apprise_target_download = "";
        apprise_target_download_enable = 0;
        apprise_target_pause_resume = "";
        apprise_target_pause_resume_enable = 0;
        apprise_target_pp = "";
        apprise_target_pp_enable = 0;
        apprise_target_complete = "";
        apprise_target_complete_enable = 1;
        apprise_target_failed = "";
        apprise_target_failed_enable = 1;
        apprise_target_disk_full = "";
        apprise_target_disk_full_enable = 0;
        apprise_target_new_login = "";
        apprise_target_new_login_enable = 1;
        apprise_target_warning = "";
        apprise_target_warning_enable = 0;
        apprise_target_error = "";
        apprise_target_error_enable = 0;
        apprise_target_queue_done = "";
        apprise_target_queue_done_enable = 0;
        apprise_target_other = "";
        apprise_target_other_enable = 1;
      };
      nscript = {
        nscript_enable = 0;
        nscript_cats = "*,";
        nscript_script = "";
        nscript_parameters = "";
        nscript_prio_startup = 0;
        nscript_prio_download = 0;
        nscript_prio_pause_resume = 0;
        nscript_prio_pp = 0;
        nscript_prio_complete = 1;
        nscript_prio_failed = 1;
        nscript_prio_disk_full = 1;
        nscript_prio_new_login = 0;
        nscript_prio_warning = 0;
        nscript_prio_error = 0;
        nscript_prio_queue_done = 0;
        nscript_prio_other = 1;
      };
      servers = {
        "news.eweka.nl" = {
          name = "news.eweka.nl";
          displayname = "news.eweka.nl";
          host = "news.eweka.nl";
          port = 563;
          timeout = 60;
          username = config.sops.placeholder.eweka-username;
          password = config.sops.placeholder.eweka-password;
          connections = 50;
          ssl = 1;
          ssl_verify = 2;
          ssl_ciphers = "";
          enable = 1;
          required = 0;
          optional = 0;
          retention = 6328;
          expire_date = "2027-06-07";
          quota = "";
          usage_at_start = 0;
          priority = 0;
          notes = "";
        };
        "news.newshosting.com" = {
          name = "news.newshosting.com";
          displayname = "news.newshosting.com";
          host = "news.newshosting.com";
          port = 563;
          timeout = 60;
          username = config.sops.placeholder.newshosting-username;
          password = config.sops.placeholder.newshosting-password;
          connections = 100;
          ssl = 1;
          ssl_verify = 2;
          ssl_ciphers = "";
          enable = 1;
          required = 0;
          optional = 0;
          retention = 6331;
          expire_date = "2027-02-28";
          quota = "";
          usage_at_start = 0;
          priority = 0;
          notes = "";
        };
        "news.easynews.com" = {
          name = "news.easynews.com";
          displayname = "news.easynews.com";
          host = "news.easynews.com";
          port = 563;
          timeout = 60;
          username = config.sops.placeholder.easynews-username;
          password = config.sops.placeholder.easynews-password;
          connections = 60;
          ssl = 1;
          ssl_verify = 2;
          ssl_ciphers = "";
          enable = 1;
          required = 0;
          optional = 0;
          retention = 6331;
          expire_date = "2027-06-07";
          quota = "";
          usage_at_start = 0;
          priority = 0;
          notes = "";
        };
        "news.bulknews.eu" = {
          name = "news.bulknews.eu";
          displayname = "news.bulknews.eu";
          host = "news.bulknews.eu";
          port = 443;
          timeout = 60;
          username = config.sops.placeholder.bulknews-username;
          password = config.sops.placeholder.bulknews-password;
          connections = 30;
          ssl = 1;
          ssl_verify = 2;
          ssl_ciphers = "";
          enable = 1;
          required = 0;
          optional = 1;
          retention = 2800;
          expire_date = "";
          quota = "6000G";
          usage_at_start = 0;
          priority = 1;
          notes = "";
        };
      };
      categories = {
        "*" = {
          name = "*";
          order = 0;
          pp = 3;
          script = "None";
          dir = "";
          newzbin = "";
          priority = 0;
        };
        music = {
          name = "music";
          order = 2;
          pp = "";
          script = "Default";
          dir = "music";
          newzbin = "";
          priority = -100;
        };
        movies = {
          name = "movies";
          order = 1;
          pp = "";
          script = "replace_for.py";
          dir = "movies";
          newzbin = "";
          priority = -100;
        };
        tv = {
          name = "tv";
          order = 0;
          pp = "";
          script = "replace_for.py";
          dir = "tv";
          newzbin = "";
          priority = -100;
        };
      };
    };
  };
in
{

  config = lib.mkIf (cfg.enable && cfg.sabnzbd.enable) {
    sops.templates."sabnzbd.ini" = {
      content = mares.infrastructure.lib.generators.toINI settings;

      # The config file path appears to define Sabnzbd's working directory, which then causes errors.
      # So we need to symlink for the configuration.
      path = config.services.sabnzbd.configFile;
      owner = cfg.sabnzbd.user;
      group = cfg.group;
      # Sabnzbd requires write access; otherwise, the UI is flooded with "Cannot write to INI file" errors.
      # And since the generated INI file slightly differ, sabnzbd will always attempt to correct it.
      mode = "0660";

      restartUnits = [ "sabnzbd.service" ];
    };
  };
}
