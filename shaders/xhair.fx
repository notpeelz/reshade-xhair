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

/**
 * General Settings
 */

uniform int OffsetX <
  ui_category = CATEGORY_GENERAL;
  ui_type = "drag";
  ui_min = -10; ui_max = 10;
  ui_label = "X Axis Shift";
> = 0;

uniform int OffsetY <
  ui_category = CATEGORY_GENERAL;
  ui_type = "drag";
  ui_min = -10; ui_max = 10;
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

uniform float OutlineThickness <
  ui_category = CATEGORY_OUTLINE;
  ui_type = "drag";
  ui_min = 0.0; ui_max = 10.0;
  ui_label = "Outline Thickness";
> = 1.0;

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

uniform bool OutlineInterpolation  <
  ui_category = CATEGORY_OUTLINE;
  //ui_type = "toggle"; // Is this needed?
  ui_label = "Outline Interpolation";
> = false;

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
  ui_min = 0; ui_max = 100;
  ui_label = "[Cross] Length";
> = 10;

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

  float totalLength = CrossLength + OutlineThickness  * 2 + 1;

  float2 center = float2((BUFFER_WIDTH / 2) - 1 + OffsetX, (BUFFER_HEIGHT / 2) - 1 + OffsetY);

  float distX = abs(center.x - pos.x);
  float distY = abs(center.y - pos.y);
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
      drawOpacity = !OutlineInterpolation
        ? OutlineOpacity * int(round(saturate(innerOutlinePixel + outerOutlinePixel)))
        : OutlineOpacity * saturate(innerOutlinePixel + outerOutlinePixel);
    }
  } else { // defaults to XhairType: Cross
    draw = float4(CrossColor, 1.0);
    drawOpacity = XhairOpacity;

    int thickness = CrossThickness * 2;
    int length = CrossLength + CrossGap;

    if (distX < distY) { // Vertical pixel

      bool isXhairPixel = int(round(min(
        max(thickness - distX, 0) / thickness,
        max(length - distY, 0)
      ))) == 1;

      float outlinePixel =
        // top and bottom margins
        max(distY - totalLength, 0) +
        // left and right margins
        max(distX - (OutlineThickness + thickness / 2.0), 0);

      if (distY < CrossGap || !isXhairPixel) {
        drawOpacity = 0;
      }

      if (OutlineThickness > 0 && !isXhairPixel && distY >= CrossGap) {
        draw = float4(OutlineColor, 1.0);
        drawOpacity = !OutlineInterpolation
          ? OutlineOpacity * int(round(saturate(1.0 - outlinePixel)))
          : OutlineOpacity * saturate(1.0 - outlinePixel);
      }

    } else { // Horizontal pixel

      bool isXhairPixel = int(round(min(
        max(thickness - distY, 0) / thickness,
        max(length - distX, 0)
      ))) == 1;

      float outlinePixel =
        // left and right margins
        max(distX - totalLength, 0) +
        // top and bottom margins
        max(distY - (OutlineThickness + thickness / 2.0), 0);

      if (distX < CrossGap || !isXhairPixel) {
        drawOpacity = 0;
      }

      if (OutlineThickness > 0 && !isXhairPixel && distX >= CrossGap) {
        draw = float4(OutlineColor, 1.0);
        drawOpacity = !OutlineInterpolation
          ? OutlineOpacity * int(round(saturate(1.0 - outlinePixel)))
          : OutlineOpacity * saturate(1.0 - outlinePixel);
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
