# Bubble Card Nix Functions
# Provides 1:1 Nix function representations for all bubble-card types
# with type assertions and action DSL
{ lib, ... }:
let
  # Helper to filter out null values from attrsets
  filterNulls = attrs: lib.filterAttrs (_: v: v != null) attrs;

  # Action DSL
  actions = {
    moreInfo = entity: {
      action = "more-info";
      target = {
        entity_id = entity;
      };
    };
    toggle = entity: {
      action = "toggle";
      target = {
        entity_id = entity;
      };
    };
    navigate = hash: {
      action = "navigate";
      navigation_path = hash;
    };
    url = url: {
      action = "url";
      url_path = url;
    };
    none = {
      action = "none";
    };
    callService = service: args: {
      action = "call-service";
      inherit service;
      target = args.target or { };
      data = args.data or { };
    };
  };

  # Sub-button helper
  mkSubButton =
    {
      main ? [ ],
      bottom ? [ ],
      mainLayout ? "inline",
      bottomLayout ? "rows",
    }:
    {
      inherit main bottom;
      main_layout = mainLayout;
      bottom_layout = bottomLayout;
    };

  # Pop-up card
  popUp =
    {
      hash,
      name ? null,
      icon ? null,
      entity ? null,
      autoClose ? null,
      closeOnClick ? false,
      closeByClickingOutside ? true,
      widthDesktop ? null,
      margin ? null,
      marginTopMobile ? null,
      marginTopDesktop ? null,
      bgColor ? null,
      bgOpacity ? null,
      bgBlur ? null,
      shadowOpacity ? null,
      hideBackdrop ? false,
      backgroundUpdate ? false,
      triggerEntity ? null,
      triggerState ? null,
      triggerClose ? false,
      openAction ? null,
      closeAction ? null,
      showHeader ? false,
      # Button options for header
      buttonType ? "name",
      showIcon ? true,
      showName ? true,
      showState ? false,
      showLastChanged ? false,
      showLastUpdated ? false,
      showAttribute ? false,
      attribute ? null,
      scrollingEffect ? true,
      forceIcon ? false,
      useAccentColor ? false,
      buttonAction ? null,
      tapAction ? null,
      doubleTapAction ? null,
      holdAction ? null,
      cardLayout ? null,
      rows ? null,
      subButton ? null,
    }:
    lib.throwIf (hash == null || hash == "") "bubble-card popUp: 'hash' is required (e.g., '#kitchen')"
      (filterNulls {
        type = "custom:bubble-card";
        card_type = "pop-up";
        inherit
          hash
          name
          icon
          entity
          buttonType
          ;
        auto_close = autoClose;
        close_on_click = closeOnClick;
        close_by_clicking_outside = closeByClickingOutside;
        width_desktop = widthDesktop;
        inherit margin;
        margin_top_mobile = marginTopMobile;
        margin_top_desktop = marginTopDesktop;
        bg_color = bgColor;
        bg_opacity = bgOpacity;
        bg_blur = bgBlur;
        shadow_opacity = shadowOpacity;
        hide_backdrop = hideBackdrop;
        background_update = backgroundUpdate;
        trigger_entity = triggerEntity;
        trigger_state = triggerState;
        trigger_close = triggerClose;
        open_action = openAction;
        close_action = closeAction;
        show_header = showHeader;
        show_icon = showIcon;
        show_name = showName;
        show_state = showState;
        show_last_changed = showLastChanged;
        show_last_updated = showLastUpdated;
        show_attribute = showAttribute;
        inherit attribute;
        scrolling_effect = scrollingEffect;
        force_icon = forceIcon;
        use_accent_color = useAccentColor;
        button_action = buttonAction;
        tap_action = tapAction;
        double_tap_action = doubleTapAction;
        hold_action = holdAction;
        card_layout = cardLayout;
        inherit rows;
        sub_button = subButton;
      });

  # Horizontal buttons stack
  horizontalButtonsStack =
    {
      buttons,
      autoOrder ? false,
      margin ? null,
      widthDesktop ? null,
      isSidebarHidden ? false,
      riseAnimation ? true,
      highlightCurrentView ? false,
      hideGradient ? false,
    }:
    lib.throwIf (buttons == null || buttons == [ ])
      "bubble-card horizontalButtonsStack: 'buttons' is required and must not be empty"
      (
        let
          # Convert button list to numbered attrs (1_link, 1_name, etc.)
          buttonAttrs = lib.foldl' (
            acc: idx:
            let
              button = builtins.elemAt buttons idx;
              prefix = toString (idx + 1);
            in
            acc
            // {
              "${prefix}_link" = button.link;
              "${prefix}_name" = button.name or null;
              "${prefix}_icon" = button.icon or null;
              "${prefix}_entity" = button.entity or null;
              "${prefix}_pir_sensor" = button.pirSensor or null;
            }
          ) { } (lib.range 0 (builtins.length buttons - 1));
        in
        filterNulls (
          {
            type = "custom:bubble-card";
            card_type = "horizontal-buttons-stack";
            auto_order = autoOrder;
            inherit margin;
            width_desktop = widthDesktop;
            is_sidebar_hidden = isSidebarHidden;
            rise_animation = riseAnimation;
            highlight_current_view = highlightCurrentView;
            hide_gradient = hideGradient;
          }
          // buttonAttrs
        )
      );

  # Button card
  button =
    {
      entity ? null,
      buttonType ? "switch",
      name ? null,
      icon ? null,
      forceIcon ? false,
      useAccentColor ? false,
      showState ? false,
      showName ? true,
      showIcon ? true,
      showLastChanged ? false,
      showLastUpdated ? false,
      showAttribute ? false,
      attribute ? null,
      scrollingEffect ? true,
      buttonAction ? null,
      tapAction ? null,
      doubleTapAction ? null,
      holdAction ? null,
      cardLayout ? null,
      rows ? null,
      subButton ? null,
      # Slider-specific options
      minValue ? null,
      maxValue ? null,
      step ? null,
      tapToSlide ? false,
      relativeSlide ? false,
      readOnlySlider ? false,
      sliderLiveUpdate ? false,
      sliderFillOrientation ? "left",
      sliderValuePosition ? "right",
      invertSliderValue ? false,
      lightSliderType ? "brightness",
      hueForceSaturation ? false,
      hueForceSaturationValue ? 100,
      allowLightSliderTo0 ? false,
      lightTransition ? false,
      lightTransitionTime ? 500,
      styles ? null,
    }:
    lib.throwIf (buttonType != "name" && (entity == null || entity == ""))
      "bubble-card button: 'entity' is required when buttonType is not 'name'"
      (filterNulls {
        type = "custom:bubble-card";
        card_type = "button";
        inherit entity;
        button_type = buttonType;
        inherit name icon;
        force_icon = forceIcon;
        use_accent_color = useAccentColor;
        show_state = showState;
        show_name = showName;
        show_icon = showIcon;
        show_last_changed = showLastChanged;
        show_last_updated = showLastUpdated;
        show_attribute = showAttribute;
        inherit attribute;
        scrolling_effect = scrollingEffect;
        button_action = buttonAction;

        tap_action = tapAction;
        double_tap_action = doubleTapAction;
        hold_action = holdAction;
        card_layout = cardLayout;
        inherit rows;
        sub_button = subButton;
        min_value = minValue;
        max_value = maxValue;
        inherit step;
        tap_to_slide = tapToSlide;
        relative_slide = relativeSlide;
        read_only_slider = readOnlySlider;
        slider_live_update = sliderLiveUpdate;
        slider_fill_orientation = sliderFillOrientation;
        slider_value_position = sliderValuePosition;
        invert_slider_value = invertSliderValue;
        light_slider_type = lightSliderType;
        hue_force_saturation = hueForceSaturation;
        hue_force_saturation_value = hueForceSaturationValue;
        allow_light_slider_to_0 = allowLightSliderTo0;
        light_transition = lightTransition;
        light_transition_time = lightTransitionTime;
        inherit styles;
      });

  # Media player card
  mediaPlayer =
    {
      entity,
      name ? null,
      icon ? null,
      forceIcon ? false,
      showState ? false,
      showName ? true,
      showIcon ? true,
      showLastChanged ? false,
      showLastUpdated ? false,
      showAttribute ? false,
      attribute ? null,
      scrollingEffect ? true,
      minVolume ? null,
      maxVolume ? null,
      coverBackground ? false,
      buttonAction ? null,
      tapAction ? null,
      doubleTapAction ? null,
      holdAction ? null,
      mainButtonsPosition ? "default",
      mainButtonsFullWidth ? null,
      mainButtonsAlignment ? "end",
      cardLayout ? null,
      rows ? null,
      subButton ? null,
      hide ? null,
    }:
    lib.throwIf (entity == null || entity == "") "bubble-card mediaPlayer: 'entity' is required"
      (filterNulls {
        type = "custom:bubble-card";
        card_type = "media-player";
        inherit entity name icon;
        force_icon = forceIcon;
        show_state = showState;
        show_name = showName;
        show_icon = showIcon;
        show_last_changed = showLastChanged;
        show_last_updated = showLastUpdated;
        show_attribute = showAttribute;
        inherit attribute;
        scrolling_effect = scrollingEffect;
        min_volume = minVolume;
        max_volume = maxVolume;
        cover_background = coverBackground;
        button_action = buttonAction;
        tap_action = tapAction;
        double_tap_action = doubleTapAction;
        hold_action = holdAction;
        main_buttons_position = mainButtonsPosition;
        main_buttons_full_width = mainButtonsFullWidth;
        main_buttons_alignment = mainButtonsAlignment;
        card_layout = cardLayout;
        inherit rows;
        sub_button = subButton;
        inherit hide;
      });

  # Cover card
  cover =
    {
      entity,
      name ? null,
      forceIcon ? false,
      showState ? false,
      showName ? true,
      showIcon ? true,
      showLastChanged ? false,
      showLastUpdated ? false,
      showAttribute ? false,
      attribute ? null,
      scrollingEffect ? true,
      iconOpen ? null,
      iconClose ? null,
      iconUp ? null,
      iconDown ? null,
      openService ? "cover.open_cover",
      stopService ? "cover.stop_cover",
      closeService ? "cover.close_cover",
      buttonAction ? null,
      tapAction ? null,
      doubleTapAction ? null,
      holdAction ? null,
      mainButtonsPosition ? "default",
      mainButtonsFullWidth ? null,
      mainButtonsAlignment ? "end",
      cardLayout ? null,
      rows ? null,
      subButton ? null,
    }:
    lib.throwIf (entity == null || entity == "") "bubble-card cover: 'entity' is required"
      (filterNulls {
        type = "custom:bubble-card";
        card_type = "cover";
        inherit entity name;
        force_icon = forceIcon;
        show_state = showState;
        show_name = showName;
        show_icon = showIcon;
        show_last_changed = showLastChanged;
        show_last_updated = showLastUpdated;
        show_attribute = showAttribute;
        inherit attribute;
        scrolling_effect = scrollingEffect;
        icon_open = iconOpen;
        icon_close = iconClose;
        icon_up = iconUp;
        icon_down = iconDown;
        open_service = openService;
        stop_service = stopService;
        close_service = closeService;
        button_action = buttonAction;
        tap_action = tapAction;
        double_tap_action = doubleTapAction;
        hold_action = holdAction;
        main_buttons_position = mainButtonsPosition;
        main_buttons_full_width = mainButtonsFullWidth;
        main_buttons_alignment = mainButtonsAlignment;
        card_layout = cardLayout;
        inherit rows;
        sub_button = subButton;
      });

  # Select card
  select =
    {
      entity,
      name ? null,
      icon ? null,
      forceIcon ? false,
      showState ? false,
      showName ? true,
      showIcon ? true,
      showLastChanged ? false,
      showLastUpdated ? false,
      showAttribute ? false,
      attribute ? null,
      scrollingEffect ? true,
      tapAction ? null,
      doubleTapAction ? null,
      holdAction ? null,
      cardLayout ? null,
      rows ? null,
      subButton ? null,
    }:
    lib.throwIf (entity == null || entity == "") "bubble-card select: 'entity' is required"
      (filterNulls {
        type = "custom:bubble-card";
        card_type = "select";
        inherit entity name icon;
        force_icon = forceIcon;
        show_state = showState;
        show_name = showName;
        show_icon = showIcon;
        show_last_changed = showLastChanged;
        show_last_updated = showLastUpdated;
        show_attribute = showAttribute;
        inherit attribute;
        scrolling_effect = scrollingEffect;
        tap_action = tapAction;
        double_tap_action = doubleTapAction;
        hold_action = holdAction;
        card_layout = cardLayout;
        inherit rows;
        sub_button = subButton;
      });

  # Climate card
  climate =
    {
      entity,
      name ? null,
      icon ? null,
      forceIcon ? false,
      showState ? false,
      showName ? true,
      showIcon ? true,
      hideTargetTempLow ? false,
      hideTargetTempHigh ? false,
      stateColor ? false,
      step ? null,
      minTemp ? null,
      maxTemp ? null,
      buttonAction ? null,
      tapAction ? null,
      doubleTapAction ? null,
      holdAction ? null,
      mainButtonsPosition ? "default",
      mainButtonsFullWidth ? null,
      mainButtonsAlignment ? "end",
      cardLayout ? null,
      rows ? null,
      subButton ? null,
    }:
    lib.throwIf (entity == null || entity == "") "bubble-card climate: 'entity' is required"
      (filterNulls {
        type = "custom:bubble-card";
        card_type = "climate";
        inherit entity name icon;
        force_icon = forceIcon;
        show_state = showState;
        show_name = showName;
        show_icon = showIcon;
        hide_target_temp_low = hideTargetTempLow;
        hide_target_temp_high = hideTargetTempHigh;
        state_color = stateColor;
        inherit step;
        min_temp = minTemp;
        max_temp = maxTemp;
        button_action = buttonAction;
        tap_action = tapAction;
        double_tap_action = doubleTapAction;
        hold_action = holdAction;
        main_buttons_position = mainButtonsPosition;
        main_buttons_full_width = mainButtonsFullWidth;
        main_buttons_alignment = mainButtonsAlignment;
        card_layout = cardLayout;
        inherit rows;
        sub_button = subButton;
      });

  # Calendar card
  calendar =
    {
      entities,
      days ? 7,
      limit ? null,
      showEnd ? false,
      showProgress ? true,
      scrollingEffect ? true,
      eventAction ? null,
      tapAction ? null,
      doubleTapAction ? null,
      holdAction ? null,
      cardLayout ? null,
      rows ? null,
      subButton ? null,
      styles ? null,
    }:
    lib.throwIf (entities == null || entities == [ ])
      "bubble-card calendar: 'entities' is required and must not be empty"
      (filterNulls {
        type = "custom:bubble-card";
        card_type = "calendar";
        inherit entities days;
        inherit limit;
        show_end = showEnd;
        show_progress = showProgress;
        scrolling_effect = scrollingEffect;
        event_action = eventAction;
        tap_action = tapAction;
        double_tap_action = doubleTapAction;
        hold_action = holdAction;
        card_layout = cardLayout;
        inherit rows;
        sub_button = subButton;
        inherit styles;
      });

  # Separator card
  separator =
    {
      name ? null,
      icon ? null,
      cardLayout ? null,
      rows ? null,
      subButton ? null,
    }:
    filterNulls {
      type = "custom:bubble-card";
      card_type = "separator";
      inherit name icon;
      card_layout = cardLayout;
      inherit rows;
      sub_button = subButton;
    };

  # Empty column card
  emptyColumn =
    { }:
    {
      type = "custom:bubble-card";
      card_type = "empty-column";
    };

  # Sub-button helper function
  subButton =
    {
      entity ? null,
      name ? null,
      icon ? null,
      type ? "default", # "default" | "slider" | "select"
      showState ? false,
      showName ? false,
      showIcon ? true,
      showBackground ? true,
      stateBackground ? true,
      lightBackground ? true,
      showLastChanged ? false,
      showLastUpdated ? false,
      showAttribute ? false,
      attribute ? null,
      selectAttribute ? null,
      showArrow ? true,
      scrollingEffect ? true,
      tapAction ? null,
      doubleTapAction ? null,
      holdAction ? null,
      fillWidth ? null,
      width ? null,
      customHeight ? null,
      contentLayout ? "icon-left",
      alwaysVisible ? false,
      showButtonInfo ? false,
      minValue ? null,
      maxValue ? null,
      step ? null,
      tapToSlide ? false,
      relativeSlide ? false,
      readOnlySlider ? false,
      sliderLiveUpdate ? false,
      sliderFillOrientation ? "left",
      sliderValuePosition ? "right",
      invertSliderValue ? false,
      lightSliderType ? "brightness",
      hueForceSaturation ? false,
      hueForceSaturationValue ? 100,
      allowLightSliderTo0 ? false,
      lightTransition ? false,
      lightTransitionTime ? 500,
      visibility ? null,
      hideWhenParentUnavailable ? false,
    }:
    filterNulls {
      inherit entity name icon;
      sub_button_type = type;
      show_state = showState;
      show_name = showName;
      show_icon = showIcon;
      show_background = showBackground;
      state_background = stateBackground;
      light_background = lightBackground;
      show_last_changed = showLastChanged;
      show_last_updated = showLastUpdated;
      show_attribute = showAttribute;
      inherit attribute;
      select_attribute = selectAttribute;
      show_arrow = showArrow;
      scrolling_effect = scrollingEffect;
      tap_action = tapAction;
      double_tap_action = doubleTapAction;
      hold_action = holdAction;
      fill_width = fillWidth;
      inherit width;
      custom_height = customHeight;
      content_layout = contentLayout;
      always_visible = alwaysVisible;
      show_button_info = showButtonInfo;
      min_value = minValue;
      max_value = maxValue;
      inherit step;
      tap_to_slide = tapToSlide;
      relative_slide = relativeSlide;
      read_only_slider = readOnlySlider;
      slider_live_update = sliderLiveUpdate;
      slider_fill_orientation = sliderFillOrientation;
      slider_value_position = sliderValuePosition;
      invert_slider_value = invertSliderValue;
      light_slider_type = lightSliderType;
      hue_force_saturation = hueForceSaturation;
      hue_force_saturation_value = hueForceSaturationValue;
      allow_light_slider_to_0 = allowLightSliderTo0;
      light_transition = lightTransition;
      light_transition_time = lightTransitionTime;
      inherit visibility;
      hide_when_parent_unavailable = hideWhenParentUnavailable;
    };

  # Sub-buttons card (card_type: sub-buttons)
  subButtons =
    {
      subButton,
      hideMainBackground ? false,
      footerMode ? false,
      footerFullWidth ? false,
      footerWidth ? null,
      footerBottomOffset ? 16,
      cardLayout ? null,
      rows ? null,
    }:
    lib.throwIf (subButton == null) "bubble-card subButtons: 'subButton' is required" (filterNulls {
      type = "custom:bubble-card";
      card_type = "sub-buttons";
      sub_button = subButton;
      hide_main_background = hideMainBackground;
      footer_mode = footerMode;
      footer_full_width = footerFullWidth;
      footer_width = footerWidth;
      footer_bottom_offset = footerBottomOffset;
      card_layout = cardLayout;
      inherit rows;
    });
in
{
  # Export all card functions and helpers
  inherit
    actions
    mkSubButton
    popUp
    horizontalButtonsStack
    button
    mediaPlayer
    cover
    select
    climate
    calendar
    separator
    emptyColumn
    subButtons
    subButton
    ;
}
