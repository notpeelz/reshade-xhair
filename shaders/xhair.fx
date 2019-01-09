/**
 * reshade-xhair 1.1
 * ReShade Crosshair Shader Overlay
 *
 *  Copyright 2019 LouisTakePILLz
 */

#include "Reshade.fxh"

#define CATEGORY_GENERAL "General"
#define CATEGORY_OUTLINE "Outline"
#define CATEGORY_XHAIR "Xhair"
#define CATEGORY_XHAIR_COMPOSITE "Composite Xhair"
#define CATEGORY_XHAIR_CROSS "[Cross] Xhair"
#define CATEGORY_XHAIR_CIRCLE "[Circle] Xhair"

#define MAX_OUTLINE_THICKNESS 10

/**
 * General Settings
 */

uniform int OffsetX <
  ui_category = CATEGORY_GENERAL;
  ui_type = "drag";
  ui_min = -(BUFFER_WIDTH / 2); ui_max = (BUFFER_WIDTH / 2);
  ui_label = "X Axis Shift";
> = 0;

uniform int OffsetY <
  ui_category = CATEGORY_GENERAL;
  ui_type = "drag";
  ui_min = -(BUFFER_HEIGHT / 2); ui_max = (BUFFER_HEIGHT / 2);
  ui_label = "Y Axis Shift";
> = 0;

uniform int HideOnRMB <
  ui_category = CATEGORY_GENERAL;
  ui_type = "combo";
  ui_items = "Hold\0Toggle\0Disabled";
  ui_label = "Hide on RMB";
> = 0;

/**
 * Outline Settings
 */

uniform bool OutlineEnabled <
  ui_category = CATEGORY_OUTLINE;
  ui_label = "Enable Outline";
> = 1;

uniform int f_outlineThickness <
  ui_category = CATEGORY_OUTLINE;
  ui_type = "drag";
  ui_min = 0; ui_max = MAX_OUTLINE_THICKNESS;
  ui_step = 1;
  ui_label = "Outline Thickness";
> = 2;
#define OutlineThickness (max(f_outlineThickness, 0))

uniform float3 OutlineColor <
  ui_category = CATEGORY_OUTLINE;
  ui_type = "color";
  ui_label = "Outline Color";
> = float3(0.0, 0.0, 0.0);

uniform float OutlineOpacity <
  ui_category = CATEGORY_OUTLINE;
  ui_type = "drag";
  ui_min = 0.0; ui_max = 1.0;
  ui_label = "Outline Opacity";
> = 1.0;

uniform int f_outlineSharpness <
  ui_category = CATEGORY_OUTLINE;
  ui_type = "drag";
  ui_min = 0; ui_max = MAX_OUTLINE_THICKNESS;
  ui_step = 1;
  ui_label = "Outline Sharpness";
> = 1;
#define OutlineSharpness (min(max(f_outlineSharpness, 0), OutlineThickness) - 1)

uniform bool OutlineGlowEnabled <
  ui_category = CATEGORY_OUTLINE;
  ui_label = "Enable Outline Glow";
> = true;

uniform float OutlineGlowModifier <
  ui_category = CATEGORY_OUTLINE;
  ui_type = "drag";
  ui_min = 0.0; ui_max = 1.0;
  ui_step = 0.005;
  ui_label = "Outline Glow Modifier";
> = 0.15;

/**
 * Xhair Settings
 */

uniform int XhairType <
  ui_category = CATEGORY_XHAIR;
  ui_type = "combo";
  ui_items = "Cross\0Circle";
  ui_label = "Xhair Type";
> = 0;

uniform float XhairOpacity <
  ui_category = CATEGORY_XHAIR;
  ui_type = "drag";
  ui_min = 0.0; ui_max = 1.0;
  ui_label = "Xhair Opacity";
> = 1.0;

/**
 * Composite Xhair Settings
 */

uniform int DotType <
  ui_category = CATEGORY_XHAIR_COMPOSITE;
  ui_type = "combo";
  ui_items = "Circle\0Square\0Disabled";
  ui_label = "Use Dot";
> = 2;

uniform int DotSize <
  ui_category = CATEGORY_XHAIR_COMPOSITE;
  ui_type = "drag";
  ui_min = 0; ui_max = 30;
  ui_label = "Dot Size";
> = 0;

uniform float DotOpacity <
  ui_category = CATEGORY_XHAIR_COMPOSITE;
  ui_type = "drag";
  ui_min = 0.0; ui_max = 1.0;
  ui_label = "Dot Opacity";
> = 1.0;

uniform float3 DotColor <
  ui_category = CATEGORY_XHAIR_COMPOSITE;
  ui_type = "color";
  ui_label = "Dot Color";
> = float3(0.0, 1.0, 0.0);

/**
 * Cross Xhair Settings
 */

uniform float3 CrossColor <
  ui_category = CATEGORY_XHAIR_CROSS;
  ui_type = "color";
  ui_label = "[Cross] Color";
> = float3(0.0, 1.0, 0.0);

uniform int CrossLength <
  ui_category = CATEGORY_XHAIR_CROSS;
  ui_type = "drag";
  ui_min = 1; ui_max = 100;
  ui_label = "[Cross] Length";
> = 6;

uniform int CrossThickness <
  ui_category = CATEGORY_XHAIR_CROSS;
  ui_type = "drag";
  ui_min = 0; ui_max = 10;
  ui_label = "[Cross] Thickness";
> = 1;

uniform int CrossGap <
  ui_category = CATEGORY_XHAIR_CROSS;
  ui_type = "drag";
  ui_min = 0; ui_max = 10;
  ui_label = "[Cross] Gap";
> = 3;

/**
 * Circle Xhair Settings
 */

uniform float3 CircleColor <
  ui_category = CATEGORY_XHAIR_CIRCLE;
  ui_type = "color";
  ui_label = "[Circle] Color";
> = float3(0.0, 1.0, 0.0);

uniform float CircleThickness <
  ui_category = CATEGORY_XHAIR_CIRCLE;
  ui_type = "drag";
  ui_min = 0.0; ui_max = 20.0;
  ui_label = "[Circle] Thickness";
> = 2.0;

uniform float CircleGapRadius <
  ui_category = CATEGORY_XHAIR_CIRCLE;
  ui_type = "drag";
  ui_min = 0.0; ui_max = 20.0;
  ui_label = "[Circle] Gap Radius";
> = 4.0;

/**
 * RMB States
 */

uniform bool rightMouseDown <
  source = "mousebutton";
  keycode = 1;
  toggle = false;
>;

uniform bool rightMouseToggle <
  source = "mousebutton";
  keycode = 1;
  mode = "toggle";
  toggle = false;
>;

/**
 * Xhair Shader
 */

static const float2 Origin = float2(0, 0);

#define OUTLINE_CORNER_POS (Origin)

#define BareCrossLength (CrossLength + CrossGap)

#define OUTLINE_GLOW_SIZE (max(OutlineThickness - OutlineSharpness, 0))
#define OUTLINE_GLOW(intensity) (OutlineGlowEnabled ? lerp(OutlineGlowModifier, 0.0, intensity) : 0.0)

#define invertSaturate(x) (1.0 - saturate((x)))
#define manhattanDistance(p1, p2) (abs(p1.x - p2.x) + abs(p1.y - p2.y))

#ifdef __DEBUG__
uniform int random1 < source = "random"; min = 0; max = 255; >;
uniform int random2 < source = "random"; min = 0; max = 255; >;
uniform int random3 < source = "random"; min = 0; max = 255; >;
#endif

float4 PS_Xhair(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
  float4 drawBackground = tex2D(ReShade::BackBuffer, texcoord);

  // Skip rendering if disabled
  if (XhairType == 2) {
    return drawBackground;
  }

  // Don't render if RMB hiding is activated
  if (HideOnRMB == 0 && rightMouseDown || HideOnRMB == 1 && rightMouseToggle) {
    return drawBackground;
  }

  float2 center = float2((BUFFER_WIDTH / 2) - 1 + OffsetX, (BUFFER_HEIGHT / 2) - 1 + OffsetY);

  int distX = abs(center.x - pos.x);
  int distY = abs(center.y - pos.y);
  float distCenter = distance(center, pos);

  float4 draw;
  float drawOpacity = 0;

  if (XhairType == 1) { // Circle
    draw = float4(CircleColor, 1.0);
    drawOpacity = XhairOpacity;

    bool isXhairPixel = int(round(
      max(CircleThickness - abs(distCenter - CircleGapRadius), 0) / CircleThickness
    )) == 1;
    float innerOutlinePixel = max(OutlineThickness - abs(distCenter - (CircleGapRadius - CircleThickness * 0.5)), 0) / OutlineThickness;
    float outerOutlinePixel = max(OutlineThickness - abs(distCenter - (CircleGapRadius + CircleThickness * 0.5)), 0) / OutlineThickness;

    if (!isXhairPixel) {
      drawOpacity = 0;
    }

    if (OutlineThickness > 0 && !isXhairPixel) {
      draw = float4(OutlineColor, 1.0);

      float outlinePixel = innerOutlinePixel + outerOutlinePixel;
      drawOpacity = saturate(
        (saturate(outlinePixel) <= OutlineSharpness
          ? OutlineOpacity * saturate(round(outlinePixel))
          : OutlineOpacity * saturate(outlinePixel) * OutlineGlowModifier
        )
      );
    }
  } else { // defaults to XhairType: Cross
    draw = float4(CrossColor, 1.0);
    drawOpacity = XhairOpacity;

    if (distX < distY) { // Vertical pixel

      bool isXhairPixel = int(round(min(
        max((CrossThickness * 2) - distX, 0) / (CrossThickness * 2.0),
        max(BareCrossLength - distY, 0)
      ))) == 1;

      // Check if we should (not) render a xhair pixel
      if (distY < CrossGap || !isXhairPixel) {
        drawOpacity = 0;
      }
      // Check if we should render an outline pixel
      if (OutlineEnabled && !isXhairPixel && distY >= CrossGap) {

        // Pixel distance from the bare crosshair (w/o the outline)
        int bareCrossDistX = distX - CrossThickness;
        int bareCrossDistY = distY - BareCrossLength;

        // Pixel distance from the sharp outline
        int sharpOutlineDistX = bareCrossDistX - OutlineSharpness;
        int sharpOutlineDistY = bareCrossDistY - OutlineSharpness;

        draw = float4(OutlineColor, 1.0);

        #ifdef __DEBUG__
        if (sharpOutlineDistX == 0 && sharpOutlineDistY == 0) {
          draw = float4(random1/255.0, random2/255.0, random3/255.0, 1);
          return draw;
        }
        #endif

        if (sharpOutlineDistX < OUTLINE_GLOW_SIZE) {
          float2 relativePos = float2(max(sharpOutlineDistX, 0), max(sharpOutlineDistY, 0));
          float dist = manhattanDistance(relativePos, OUTLINE_CORNER_POS);
          float glowIntensity = saturate(dist / float(OUTLINE_GLOW_SIZE));
          drawOpacity = dist > OutlineSharpness
            ? OUTLINE_GLOW(glowIntensity)
            : 1.0;
          drawOpacity *= OutlineOpacity;
        }
      }

    } else { // Horizontal pixel

      bool isXhairPixel = int(round(min(
        max((CrossThickness * 2.0) - distY, 0) / (CrossThickness * 2.0),
        max(BareCrossLength - distX, 0)
      ))) == 1;

      // Check if we should (not) render a xhair pixel
      if (distX < CrossGap || !isXhairPixel) {
        drawOpacity = 0;
      }

      // Check if we should render an outline pixel
      if (OutlineEnabled && !isXhairPixel && distX >= CrossGap) {

        // Pixel distance from the bare crosshair (w/o the outline)
        int bareCrossDistX = distX - BareCrossLength;
        int bareCrossDistY = distY - CrossThickness;

        // Pixel distance from the sharp outline
        int sharpOutlineDistX = bareCrossDistX - OutlineSharpness;
        int sharpOutlineDistY = bareCrossDistY - OutlineSharpness;

        draw = float4(OutlineColor, 1.0);

        #ifdef __DEBUG__
        if (sharpOutlineDistX == 0 && sharpOutlineDistY == 0) {
          draw = float4(random1/255.0, random2/255.0, random3/255.0, 1);
          return draw;
        }
        #endif

        if (sharpOutlineDistY < OUTLINE_GLOW_SIZE) {
          float2 relativePos = float2(max(sharpOutlineDistX, 0), max(sharpOutlineDistY, 0));
          float dist = manhattanDistance(relativePos, OUTLINE_CORNER_POS);
          float glowIntensity = saturate(dist / float(OUTLINE_GLOW_SIZE));
          drawOpacity = dist > OutlineSharpness
            ? OUTLINE_GLOW(glowIntensity)
            : 1.0;
          drawOpacity *= OutlineOpacity;
        }
      }

    }
  }

  if (
    // Dot: Circle
    (DotType == 0 && distCenter <= DotSize) ||
    // Dot: Square
    (DotType == 1 && distX <= DotSize && distY <= DotSize)
  ) {
    draw = float4(DotColor, 1.0);
    drawOpacity = DotOpacity;
  }

  return lerp(drawBackground, draw, drawOpacity);
}

technique xhair {
  pass HudPass {
    VertexShader = PostProcessVS;
    PixelShader = PS_Xhair;
  }
}
