/**
 * reshade-xhair 1.1
 * ReShade Crosshair Shader Overlay
 *
 *  Copyright 2019 LouisTakePILLz
 */

#include "Reshade.fxh"

uniform int OffsetX <
    ui_type = "drag";
    ui_min = -10; ui_max = 10;
    ui_label = "X Axis Shift";
> = 0;

uniform int OffsetY <
    ui_type = "drag";
    ui_min = -10; ui_max = 10;
    ui_label = "Y Axis Shift";
> = 0;

uniform int XhairType <
    ui_type = "combo";
    ui_items = "Cross\0Circle";
    ui_label = "Xhair Type";
> = 0;

uniform float XhairOpacity <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 1.0;
    ui_label = "Xhair Opacity";
> = 1.0;

uniform float OutlineThickness <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 10.0;
    ui_label = "Outline Thickness";
> = 1.0;

uniform float3 OutlineColor <
    ui_type = "color";
    ui_label = "Outline Color";
> = float3(0.0, 0.0, 0.0);

uniform float OutlineOpacity <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 1.0;
    ui_label = "Outline Opacity";
> = 1.0;

uniform bool OutlineInterpolation  <
    ui_type = "toggle";
    ui_label = "Outline Interpolation";
> = false;

uniform int DotType <
    ui_type = "combo";
    ui_items = "Circle\0Square\0Disabled";
    ui_label = "Use Dot";
> = 2;

uniform int DotSize <
    ui_type = "drag";
    ui_min = 0; ui_max = 30;
    ui_label = "Dot Size";
> = 0;

uniform float DotOpacity <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 1.0;
    ui_label = "Dot Opacity";
> = 1.0;

uniform float3 DotColor <
    ui_type = "color";
    ui_label = "Dot Color";
> = float3(0.0, 1.0, 0.0);

uniform float3 CrossColor <
    ui_type = "color";
    ui_label = "[Cross] Color";
> = float3(0.0, 1.0, 0.0);

uniform int CrossLength <
    ui_type = "drag";
    ui_min = 0; ui_max = 100;
    ui_label = "[Cross] Length";
> = 10;

uniform int CrossThickness <
    ui_type = "drag";
    ui_min = 0; ui_max = 10;
    ui_label = "[Cross] Thickness";
> = 1;

uniform int CrossGap <
    ui_type = "drag";
    ui_min = 0; ui_max = 10;
    ui_label = "[Cross] Gap";
> = 3;

uniform float3 CircleColor <
    ui_type = "color";
    ui_label = "[Circle] Color";
> = float3(0.0, 1.0, 0.0);

uniform float CircleThickness <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 20.0;
    ui_label = "[Circle] Thickness";
> = 2.0;

uniform float CircleGapRadius <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 20.0;
    ui_label = "[Circle] Gap Radius";
> = 4.0;

uniform int HideOnRMB <
    ui_type = "combo";
    ui_items = "Hold\0Toggle\0Disabled";
    ui_label = "Hide on RMB";
> = 0;

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

    float4 draw = float4(0, 0, 0, 1.0);
    float2 center = float2((BUFFER_WIDTH / 2) - 1 + OffsetX, (BUFFER_HEIGHT / 2) - 1 + OffsetY);

    float distX = abs(center.x - pos.x);
    float distY = abs(center.y - pos.y);
    float distCenter = distance(center, pos);

    float drawOpacity = 0;

    if (
        // Dot: Circle
        (DotType == 0 && distCenter <= DotSize) ||
        // Dot: Square
        (DotType == 1 && distX <= DotSize && distY <= DotSize)
    ) {
        draw = float4(DotColor, 1.0);
        drawOpacity = DotOpacity;
    } else if (XhairType == 1) { // Circle
        draw = float4(CircleColor, 1.0);
        drawOpacity = XhairOpacity;

        bool xhairPixel = int(round(max(CircleThickness - abs(distCenter - CircleGapRadius), 0) / CircleThickness)) == 1;
        float innerOutlinePixel = max(OutlineThickness - abs(distCenter - (CircleGapRadius - CircleThickness * 0.5)), 0) / OutlineThickness;
        float outerOutlinePixel = max(OutlineThickness - abs(distCenter - (CircleGapRadius + CircleThickness * 0.5)), 0) / OutlineThickness;

        if (!xhairPixel) {
            drawOpacity = 0;
        }

        if (OutlineThickness > 0 && !xhairPixel) {
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

        if (distX < distY) { // Vertical

            bool xhairPixel = int(round(min(
                max(thickness - distX, 0) / thickness,
                max(length - distY, 0)
            ))) == 1;

            float outlinePixel =
                // top and bottom margins
                max(distY - totalLength, 0) +
                // left and right margins
                max(distX - (OutlineThickness + thickness / 2.0), 0);

            if (distY < CrossGap || !xhairPixel) {
                drawOpacity = 0;
            }

            if (OutlineThickness > 0 && !xhairPixel && distY >= CrossGap) {
                draw = float4(OutlineColor, 1.0);
                drawOpacity = !OutlineInterpolation
                    ? OutlineOpacity * int(round(saturate(1.0 - outlinePixel)))
                    : OutlineOpacity * saturate(1.0 - outlinePixel);
            }

        } else { // Horizontal

            bool xhairPixel = int(round(min(
                max(thickness - distY, 0) / thickness,
                max(length - distX, 0)
            ))) == 1;

            float outlinePixel =
                // left and right margins
                max(distX - totalLength, 0) +
                // top and bottom margins
                max(distY - (OutlineThickness + thickness / 2.0), 0);

            if (distX < CrossGap || !xhairPixel) {
                drawOpacity = 0;
            }

            if (OutlineThickness > 0 && !xhairPixel && distX >= CrossGap) {
                draw = float4(OutlineColor, 1.0);
                drawOpacity = !OutlineInterpolation
                    ? OutlineOpacity * int(round(saturate(1.0 - outlinePixel)))
                    : OutlineOpacity * saturate(1.0 - outlinePixel);
            }

        }
    }

    return lerp(drawBackground, draw, drawOpacity);
}

technique xhair {
    pass HudPass {
        VertexShader = PostProcessVS;
        PixelShader = PS_Xhair;
    }
}