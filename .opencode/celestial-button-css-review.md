# Mares Home v1 Dashboard - Celestial Button CSS Review

## Current CSS Analysis

The current celestial button implementation has issues:
1. Overlay masks the content (sub-buttons hard to read)
2. Complex pseudo-element positioning
3. May be using wrong CSS classes

## Proposed Simplification

Using `border-left` for the progress indicator is cleaner:

```css
.bubble-button {
  /* Gradient background for entire button */
  background: linear-gradient(
    to right,
    #0d1b2a 0%,
    #1b263b 15%,
    #2d3a4a 25%,
    #5d4e37 35%,
    #778899 50%,
    #6b4c4c 65%,
    #3d3a4a 80%,
    #0d1b2a 100%
  );
  
  /* Progress indicator as left border at current time position */
  border-left: 2px solid rgba(255, 255, 255, 0.8);
  border-left-width: ''${hass.states['sensor.day_progress']?.state || 50}%;
  
  /* Darken the right side (future) - simpler approach */
  box-shadow: inset -100px 0 100px -100px rgba(21, 27, 36, 0.85);
}
```

Actually, `border-left` doesn't work well for positioning. Better approach:

```css
.bubble-button {
  background: linear-gradient(
    to right,
    #0d1b2a 0%,
    #1b263b 15%,
    #2d3a4a 25%,
    #5d4e37 35%,
    #778899 50%,
    #6b4c4c 65%,
    #3d3a4a 80%,
    #0d1b2a 100%
  );
  position: relative;
}

/* Current time line - positioned without overlaying content */
.bubble-button::before {
  content: "";
  position: absolute;
  left: ''${hass.states['sensor.day_progress']?.state || 50}%;
  top: 10%;  /* Don't go full height */
  bottom: 10%;
  width: 2px;
  background: rgba(255, 255, 255, 0.8);
  pointer-events: none;  /* Let clicks pass through */
}

/* Gradient overlay for unfilled portion - at very low z-index */
.bubble-button::after {
  content: "";
  position: absolute;
  left: ''${hass.states['sensor.day_progress']?.state || 50}%;
  top: 0;
  right: 0;
  bottom: 0;
  background: linear-gradient(to right, rgba(21, 27, 36, 0.3), rgba(21, 27, 36, 0.7));
  z-index: -1;  /* Behind content */
  pointer-events: none;
}
```

## Key Improvements

1. **Use `pointer-events: none`** - Line doesn't block interactions
2. **Shorter line** - `top: 10%; bottom: 10%` instead of full height
3. **Negative z-index** - Overlay goes behind content
4. **Simpler approach** - Maybe just use the gradient without masking?

## Alternative: No Masking

Just show the full gradient all the time with the progress line:
```css
.bubble-button {
  background: linear-gradient(...);
}

.bubble-button::before {
  /* Just show a line at current position */
  left: ''${hass.states['sensor.day_progress']?.state || 50}%;
  ...
}
```

This is much simpler and content remains fully readable!
