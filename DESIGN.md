# Design System: The Digital Atelier

## 1. Overview & Creative North Star: "The Curated Canvas"
This design system moves away from the utilitarian "grid of items" typical of fashion apps, instead embracing the philosophy of **The Curated Canvas**. It treats the user’s wardrobe as a high-end editorial gallery. 

The aesthetic is driven by **Scandinavian Minimalism**—prioritizing function and light—intertwined with **Quiet Luxury**, which emphasizes tactility and restraint. We break the "template" look through:
*   **Intentional Asymmetry:** Utilizing staggered card layouts to mimic a physical mood board.
*   **Breathing Room:** Using aggressive whitespace to ensure the user’s clothing photography remains the focal point.
*   **Tonal Depth:** Replacing harsh structural lines with soft shifts in warmth and light.

---

## 2. Colors & Surface Philosophy
The palette is rooted in organic, skin-toned neutrals contrasted by a high-energy "Golden Hour" gradient.

### Palette Highlights
*   **Background (`#faf9f8`):** An off-white "Gallery Bone" that reduces eye strain and feels more premium than pure white.
*   **Primary Gradient:** From `primary_container` (#ff8c00) to `secondary_container` (#fd9e78). This represents the warmth of a dressing room vanity.
*   **Typography:** `on_surface` (#1a1c1c) for authoritative headlines; `on_surface_variant` (#564334) for a softer, charcoal-sepia secondary text.

### The "No-Line" Rule
**Borders are prohibited for sectioning.** To separate a wardrobe category from a "Daily Look" suggestion, use background shifts. Place a `surface_container_low` section directly against a `surface` background. The change in tone is the boundary.

### Surface Hierarchy & Nesting
Treat the UI as layers of fine parchment. 
*   **Base:** `surface`
*   **Secondary Content Areas:** `surface_container_low`
*   **Interactive Cards:** `surface_container_lowest` (pure white) to create a subtle "pop" from the off-white background.

### The "Glass & Gradient" Rule
For floating elements like "Add to Outfit" FABs or Navigation Bars, use **Glassmorphism**.
*   **Style:** `surface_container_lowest` at 70% opacity with a `24px` backdrop-blur. This creates an ethereal, high-end feel where the colors of the user's clothing softly bleed through the UI.

---

## 3. Typography: The Editorial Voice
We use **Manrope** for its geometric yet warm character in headlines, and **Inter** for precision-focused labels.

*   **Display-LG (Manrope, 3.5rem):** Reserved for "Zero-State" screens or large seasonal headers. Use -0.02em letter spacing.
*   **Headline-MD (Manrope, 1.75rem):** Used for wardrobe category titles (e.g., "Summer Silks"). 
*   **Title-SM (Manrope, 1rem):** The standard for item names. Bold weight for "Quiet Luxury" authority.
*   **Label-MD (Inter, 0.75rem):** Used for metadata like "Last worn 2 days ago." Inter’s high x-height ensures readability at small scales.

---

## 4. Elevation & Depth: Tonal Layering
Traditional drop shadows are often too "heavy" for Scandinavian design. We use **Tonal Layering** and **Ambient Shadows**.

*   **The Layering Principle:** To highlight a specific card, do not add a border. Place a `surface_container_lowest` card on a `surface_container_high` background.
*   **Ambient Shadows:** For floating elements, use a shadow with a 32px blur, 0px spread, and 4% opacity. The shadow color must be `on_surface` (#1a1c1c), never pure black.
*   **The "Ghost Border" Fallback:** If a container requires definition against a similar background, use `outline_variant` at **15% opacity**. It should be felt, not seen.

---

## 5. Components

### Buttons: The Capsule Aesthetic
*   **Shape:** Always `9999px` (Full Rounding) to create a "Capsule" shape.
*   **Primary:** A linear gradient from `primary` (#904d00) to `secondary` (#934a2a). This provides a "Liquid Gold" effect.
*   **Secondary:** No background. A "Ghost Border" (outline-variant at 20%) with `on_surface` text.
*   **Interaction:** On press, the button should scale down to 96%—a tactile "click" sensation.

### Wardrobe Cards
*   **Forbid Dividers:** Use `1.5rem` (md) spacing to separate items.
*   **Styling:** Use `DEFAULT` (1rem) corner radius. The image should be the full container width.
*   **Detailing:** Item price or status should be an overlay "Glass Chip" in the top right corner.

### Bottom Navigation
*   **Container:** Glassmorphic `surface_container_lowest` (70% opacity) with a `3rem` (xl) corner radius, floating 16px from the bottom edge.
*   **Icons:** Use thin-stroke (1.5px) icons. The active state is indicated by a soft `primary_fixed` (#ffdcc3) circular glow behind the icon, not a heavy bar.

### Input Fields
*   **Style:** Minimalist. No bottom line or box. Use a `surface_container_low` background with `DEFAULT` rounding.
*   **Active State:** The background shifts to `surface_container_lowest` with a subtle 1px "Ghost Border."

---

## 6. Do’s and Don’ts

### Do:
*   **Do** use asymmetrical margins. A 24px left margin and a 16px right margin can make a photo gallery feel like a luxury magazine layout.
*   **Do** use "Manrope" for all price points and brand names to maintain the premium editorial feel.
*   **Do** utilize `surface_bright` for highlight moments, like "New In" notifications.

### Don’t:
*   **Don't** use 1px solid dividers. Use `2rem` (lg) of vertical whitespace instead.
*   **Don't** use pure black (#000000). It kills the "Quiet Luxury" softness. Always use `on_surface`.
*   **Don't** use sharp 90-degree corners. Even the smallest chip must have at least a `sm` (0.5rem) radius to stay "Soft Minimalist."