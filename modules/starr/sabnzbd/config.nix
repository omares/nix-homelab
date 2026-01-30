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

  publicSettings = {
    misc = {
      helpful_warnings = true;
      queue_complete = "";
      queue_complete_pers = false;
      bandwidth_perc = 80;
      refresh_rate = 1;
      interface_settings = "";
      queue_limit = 20;
      config_lock = false;
      fixed_ports = true;
      notified_new_skin = 2;
      direct_unpack_tested = false;
      sorters_converted = true;
      check_new_rel = true;
      auto_browser = false;
      language = "en";
      enable_https_verification = true;
      host = cfg.sabnzbd.bindAddress;
      port = 8080;
      https_port = "";
      bandwidth_max = "14M";
      cache_limit = "978.8 M";
      web_dir = "Glitter";
      web_color = "Auto";
      https_cert = null;
      https_key = null;
      enable_https = false;
      inet_exposure = 0;
      socks5_proxy_url = "";
      permissions = "";
      download_dir = "/mnt/media/usenet/incomplete";
      download_free = "";
      complete_dir = "/mnt/media/usenet/complete";
      complete_free = "";
      fulldisk_autoresume = false;
      script_dir = "${scriptsDir}";
      nzb_backup_dir = "nzb-backup";
      admin_dir = "admin";
      backup_dir = "";
      dirscan_dir = "";
      dirscan_speed = 5;
      password_file = "";
      log_dir = "logs";
      max_art_tries = 3;
      top_only = false;
      sfv_check = true;
      script_can_fail = false;
      enable_recursive = true;
      flat_unpack = true;
      par_option = "";
      pre_check = false;
      nice = "";
      win_process_prio = 3;
      ionice = "";
      fail_hopeless_jobs = true;
      fast_fail = true;
      auto_disconnect = true;
      pre_script = "clean.py";
      end_queue_script = "None";
      no_dupes = true;
      no_series_dupes = false;
      no_smart_dupes = true;
      dupes_propercheck = true;
      pause_on_pwrar = true;
      ignore_samples = false;
      deobfuscate_final_filenames = true;
      auto_sort = "";
      direct_unpack = true;
      propagation_delay = 0;
      folder_rename = true;
      replace_spaces = false;
      replace_underscores = false;
      replace_dots = false;
      safe_postproc = true;
      pause_on_post_processing = false;
      enable_all_par = false;
      sanitize_safe = false;
      cleanup_list = ",";
      unwanted_extensions = "ade, adp, app, application, appref-ms, asp, aspx, asx, bas, bat, bgi, cab, cer, chm, cmd, cnt, com, cpl, crt, csh, der, diagcab, exe, fxp, gadget, grp, hlp, hpj, hta, htc, inf, ins, iso, isp, its, jar, jnlp, js, jse, ksh, lnk, mad, maf, mag, mam, maq, mar, mas, mat, mau, mav, maw, mcf, mda, mdb, mde, mdt, mdw, mdz, msc, msh, msh1, msh2, mshxml, msh1xml, msh2xml, msi, msp, mst, msu, ops, osd, pcd, pif, pl, plg, prf, prg, printerexport, ps1, ps1xml, ps2, ps2xml, psc1, psc2, psd1, psdm1, pst, py, pyc, pyo, pyw, pyz, pyzw, reg, scf, scr, sct, shb, shs, theme, tmp, url, vb, vbe, vbp, vbs, vhd, vhdx, vsmacros, vsw, webpnp, website, ws, wsc, wsf, wsh, xbap, xll, xnk";
      action_on_unwanted_extensions = 2;
      unwanted_extensions_mode = 0;
      new_nzb_on_failure = false;
      history_retention = "";
      history_retention_option = "all";
      history_retention_number = 1;
      quota_size = "";
      quota_day = "";
      quota_resume = 0;
      quota_period = "m";
      enable_tv_sorting = false;
      tv_sort_string = "";
      tv_categories = "tv,";
      enable_movie_sorting = false;
      movie_sort_string = "";
      movie_sort_extra = "-cd%1";
      movie_categories = "movies,";
      enable_date_sorting = false;
      date_sort_string = "";
      date_categories = "tv,";
      schedlines = "1 0 1 1234567 speedlimit 0, 1 0 7 1234567 speedlimit 3m";
      rss_rate = 60;
      ampm = false;
      start_paused = false;
      preserve_paused_state = false;
      enable_par_cleanup = true;
      process_unpacked_par2 = true;
      enable_multipar = true;
      enable_unrar = true;
      enable_7zip = true;
      enable_filejoin = true;
      enable_tsjoin = true;
      overwrite_files = false;
      ignore_unrar_dates = false;
      backup_for_duplicates = false;
      empty_postproc = false;
      wait_for_dfolder = false;
      rss_filenames = false;
      api_logging = true;
      html_login = true;
      disable_archive = false;
      warn_dupl_jobs = false;
      keep_awake = true;
      tray_icon = true;
      allow_incomplete_nzb = false;
      enable_broadcast = true;
      ipv6_hosting = false;
      ipv6_staging = false;
      api_warnings = true;
      no_penalties = false;
      x_frame_options = true;
      allow_old_ssl_tls = false;
      enable_season_sorting = true;
      verify_xff_header = false;
      rss_odd_titles = "nzbindex.nl/, nzbindex.com/, nzbclub.com/";
      quick_check_ext_ignore = "nfo, sfv, srr";
      req_completion_rate = "100.2";
      selftest_host = "self-test.sabnzbd.org";
      movie_rename_limit = "100M";
      episode_rename_limit = "20M";
      size_limit = false;
      direct_unpack_threads = 3;
      history_limit = 10;
      wait_ext_drive = 5;
      max_foldername_length = 246;
      nomedia_marker = "";
      ipv6_servers = true;
      url_base = "/sabnzbd";
      host_whitelist = "nixos,";
      local_ranges = ",";
      max_url_retries = 10;
      downloader_sleep_time = 10;
      receive_threads = 2;
      switchinterval = "0.005";
      ssdp_broadcast_interval = 15;
      ext_rename_ignore = ",";
      email_server = "";
      email_to = ",";
      email_from = "";
      email_account = "";
      email_pwd = "";
      email_endjob = 0;
      email_full = false;
      email_dir = "";
      email_rss = false;
      email_cats = "*,";
      config_conversion_version = 4;
      disable_par2cmdline = false;
    };
    logging = {
      log_level = true;
      max_log_size = 5242880;
      log_backups = 5;
    };
    ncenter = {
      ncenter_enable = false;
      ncenter_cats = "*,";
      ncenter_prio_startup = false;
      ncenter_prio_download = false;
      ncenter_prio_pause_resume = false;
      ncenter_prio_pp = false;
      ncenter_prio_complete = true;
      ncenter_prio_failed = true;
      ncenter_prio_disk_full = true;
      ncenter_prio_new_login = false;
      ncenter_prio_warning = false;
      ncenter_prio_error = false;
      ncenter_prio_queue_done = false;
      ncenter_prio_other = true;
    };
    acenter = {
      acenter_enable = false;
      acenter_cats = "*,";
      acenter_prio_startup = false;
      acenter_prio_download = false;
      acenter_prio_pause_resume = false;
      acenter_prio_pp = false;
      acenter_prio_complete = true;
      acenter_prio_failed = true;
      acenter_prio_disk_full = true;
      acenter_prio_new_login = false;
      acenter_prio_warning = false;
      acenter_prio_error = false;
      acenter_prio_queue_done = false;
      acenter_prio_other = true;
    };
    ntfosd = {
      ntfosd_enable = true;
      ntfosd_cats = "*,";
      ntfosd_prio_startup = false;
      ntfosd_prio_download = false;
      ntfosd_prio_pause_resume = false;
      ntfosd_prio_pp = false;
      ntfosd_prio_complete = true;
      ntfosd_prio_failed = true;
      ntfosd_prio_disk_full = true;
      ntfosd_prio_new_login = false;
      ntfosd_prio_warning = false;
      ntfosd_prio_error = false;
      ntfosd_prio_queue_done = false;
      ntfosd_prio_other = true;
    };
    prowl = {
      prowl_enable = false;
      prowl_cats = "*,";
      prowl_apikey = "";
      prowl_prio_startup = -3;
      prowl_prio_download = -3;
      prowl_prio_pause_resume = -3;
      prowl_prio_pp = -3;
      prowl_prio_complete = false;
      prowl_prio_failed = true;
      prowl_prio_disk_full = true;
      prowl_prio_new_login = -3;
      prowl_prio_warning = -3;
      prowl_prio_error = -3;
      prowl_prio_queue_done = -3;
      prowl_prio_other = false;
    };
    pushover = {
      pushover_token = "";
      pushover_userkey = "";
      pushover_device = "";
      pushover_emergency_expire = 3600;
      pushover_emergency_retry = 60;
      pushover_enable = false;
      pushover_cats = "*,";
      pushover_prio_startup = -3;
      pushover_prio_download = -2;
      pushover_prio_pause_resume = -2;
      pushover_prio_pp = -3;
      pushover_prio_complete = -1;
      pushover_prio_failed = -1;
      pushover_prio_disk_full = true;
      pushover_prio_new_login = -3;
      pushover_prio_warning = true;
      pushover_prio_error = true;
      pushover_prio_queue_done = -3;
      pushover_prio_other = -1;
    };
    pushbullet = {
      pushbullet_enable = false;
      pushbullet_cats = "*,";
      pushbullet_apikey = "";
      pushbullet_device = "";
      pushbullet_prio_startup = false;
      pushbullet_prio_download = false;
      pushbullet_prio_pause_resume = false;
      pushbullet_prio_pp = false;
      pushbullet_prio_complete = true;
      pushbullet_prio_failed = true;
      pushbullet_prio_disk_full = true;
      pushbullet_prio_new_login = false;
      pushbullet_prio_warning = false;
      pushbullet_prio_error = false;
      pushbullet_prio_queue_done = false;
      pushbullet_prio_other = true;
    };
    apprise = {
      apprise_enable = false;
      apprise_cats = "*,";
      apprise_urls = "";
      apprise_target_startup = "";
      apprise_target_startup_enable = false;
      apprise_target_download = "";
      apprise_target_download_enable = false;
      apprise_target_pause_resume = "";
      apprise_target_pause_resume_enable = false;
      apprise_target_pp = "";
      apprise_target_pp_enable = false;
      apprise_target_complete = "";
      apprise_target_complete_enable = true;
      apprise_target_failed = "";
      apprise_target_failed_enable = true;
      apprise_target_disk_full = "";
      apprise_target_disk_full_enable = false;
      apprise_target_new_login = "";
      apprise_target_new_login_enable = true;
      apprise_target_warning = "";
      apprise_target_warning_enable = false;
      apprise_target_error = "";
      apprise_target_error_enable = false;
      apprise_target_queue_done = "";
      apprise_target_queue_done_enable = false;
      apprise_target_other = "";
      apprise_target_other_enable = true;
    };
    nscript = {
      nscript_enable = false;
      nscript_cats = "*,";
      nscript_script = "";
      nscript_parameters = "";
      nscript_prio_startup = false;
      nscript_prio_download = false;
      nscript_prio_pause_resume = false;
      nscript_prio_pp = false;
      nscript_prio_complete = true;
      nscript_prio_failed = true;
      nscript_prio_disk_full = true;
      nscript_prio_new_login = false;
      nscript_prio_warning = false;
      nscript_prio_error = false;
      nscript_prio_queue_done = false;
      nscript_prio_other = true;
    };
    servers = {
      "news.eweka.nl" = {
        name = "news.eweka.nl";
        displayname = "news.eweka.nl";
        host = "news.eweka.nl";
        port = 563;
        timeout = 60;
        connections = 50;
        ssl = true;
        ssl_verify = 2;
        ssl_ciphers = "";
        enable = true;
        required = false;
        optional = false;
        retention = 6328;
        expire_date = "2027-06-07";
        quota = "";
        usage_at_start = false;
        priority = 0;
        notes = "";
      };
      "news.newshosting.com" = {
        name = "news.newshosting.com";
        displayname = "news.newshosting.com";
        host = "news.newshosting.com";
        port = 563;
        timeout = 60;
        connections = 100;
        ssl = true;
        ssl_verify = 2;
        ssl_ciphers = "";
        enable = true;
        required = false;
        optional = false;
        retention = 6331;
        expire_date = "2027-02-28";
        quota = "";
        usage_at_start = false;
        priority = 0;
        notes = "";
      };
      "news.easynews.com" = {
        name = "news.easynews.com";
        displayname = "news.easynews.com";
        host = "news.easynews.com";
        port = 563;
        timeout = 60;
        connections = 60;
        ssl = true;
        ssl_verify = 2;
        ssl_ciphers = "";
        enable = true;
        required = false;
        optional = false;
        retention = 6331;
        expire_date = "2027-06-07";
        quota = "";
        usage_at_start = false;
        priority = 0;
        notes = "";
      };
      "news.bulknews.eu" = {
        name = "news.bulknews.eu";
        displayname = "news.bulknews.eu";
        host = "news.bulknews.eu";
        port = 443;
        timeout = 60;
        connections = 30;
        ssl = true;
        ssl_verify = 2;
        ssl_ciphers = "";
        enable = true;
        required = false;
        optional = true;
        retention = 2800;
        expire_date = "";
        quota = "6000G";
        usage_at_start = false;
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

  secretSettings = {
    misc = {
      username = config.sops.placeholder.sabnzbd-username;
      password = config.sops.placeholder.sabnzbd-password;
      api_key = config.sops.placeholder.sabnzbd-api_key;
      nzb_key = config.sops.placeholder.sabnzbd-nzb_key;
    };
    servers = {
      "news.eweka.nl" = {
        username = config.sops.placeholder.eweka-username;
        password = config.sops.placeholder.eweka-password;
      };
      "news.newshosting.com" = {
        username = config.sops.placeholder.newshosting-username;
        password = config.sops.placeholder.newshosting-password;
      };
      "news.easynews.com" = {
        username = config.sops.placeholder.easynews-username;
        password = config.sops.placeholder.easynews-password;
      };
      "news.bulknews.eu" = {
        username = config.sops.placeholder.bulknews-username;
        password = config.sops.placeholder.bulknews-password;
      };
    };
  };
in
{

  config = lib.mkIf (cfg.enable && cfg.sabnzbd.enable) {

    # Public sabnzbd settings
    services.sabnzbd = {
      settings = publicSettings;
      secretFiles = [ config.sops.templates."sabnzbd-secrets.ini".path ];
    };

    sops.templates."sabnzbd-secrets.ini" = {
      content = mares.infrastructure.lib.generators.toINI {
        globalSection = { };
        sections = secretSettings;
      };
      owner = cfg.sabnzbd.user;
      group = cfg.group;
      mode = "0660";
    };
  };
}
