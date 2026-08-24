---
name: Full-stack AI Translator
colors:
  surface: '#f9f9ff'
  surface-dim: '#d8d9e3'
  surface-bright: '#f9f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f2f3fd'
  surface-container: '#ecedf7'
  surface-container-high: '#e6e7f2'
  surface-container-highest: '#e1e2ec'
  on-surface: '#191b23'
  on-surface-variant: '#424754'
  inverse-surface: '#2e3038'
  inverse-on-surface: '#eff0fa'
  outline: '#727785'
  outline-variant: '#c2c6d6'
  surface-tint: '#005ac2'
  primary: '#0058be'
  on-primary: '#ffffff'
  primary-container: '#2170e4'
  on-primary-container: '#fefcff'
  inverse-primary: '#adc6ff'
  secondary: '#006c49'
  on-secondary: '#ffffff'
  secondary-container: '#6cf8bb'
  on-secondary-container: '#00714d'
  tertiary: '#924700'
  on-tertiary: '#ffffff'
  tertiary-container: '#b75b00'
  on-tertiary-container: '#fffbff'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#d8e2ff'
  primary-fixed-dim: '#adc6ff'
  on-primary-fixed: '#001a42'
  on-primary-fixed-variant: '#004395'
  secondary-fixed: '#6ffbbe'
  secondary-fixed-dim: '#4edea3'
  on-secondary-fixed: '#002113'
  on-secondary-fixed-variant: '#005236'
  tertiary-fixed: '#ffdcc6'
  tertiary-fixed-dim: '#ffb786'
  on-tertiary-fixed: '#311400'
  on-tertiary-fixed-variant: '#723600'
  background: '#f9f9ff'
  on-background: '#191b23'
  surface-variant: '#e1e2ec'
typography:
  display-lg:
    fontFamily: inter
    fontSize: 48px
    fontWeight: '700'
    lineHeight: '1.2'
    letterSpacing: -0.02em
  headline-md:
    fontFamily: inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  headline-sm:
    fontFamily: inter
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  body-reading:
    fontFamily: merriweather
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 32px
  body-reading-mobile:
    fontFamily: merriweather
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 28px
  ui-medium:
    fontFamily: inter
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
  ui-small:
    fontFamily: inter
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
  label-caps:
    fontFamily: inter
    fontSize: 11px
    fontWeight: '700'
    lineHeight: 12px
    letterSpacing: 0.05em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 4px
  container-margin: 24px
  gutter: 16px
  sidebar-width: 260px
  panel-padding: 32px
---

## Brand & Style
The design system is engineered for a high-performance productivity environment tailored for literary translation. The brand personality is **Professional, Academic, and Quiet**. It prioritizes "deep work" and minimizes cognitive load to support users spending hours reading and editing complex text.

The visual style is **Corporate / Modern** with a strong emphasis on **Literary Minimalism**. It leverages the familiarity of high-end SaaS platforms while introducing editorial touches that respect the long-form nature of novel content. The interface recedes to let the text lead, using clear hierarchy and purposeful whitespace to organize dense linguistic data.

## Colors
The palette is anchored in a reliable "SaaS Blue" (`#3B82F6`) for primary actions, providing a sense of technological precision. This is balanced by an Emerald secondary color used for success states and "Completed" statuses, reinforcing a sense of progress.

The UI utilizes an **Off-white background** (`#F9FAFB`) to reduce the harshness of pure white during long sessions, while **Pure White** (`#FFFFFF`) is reserved for the primary workspace surfaces (the "paper" of the novel). Text contrast is strictly managed: Deep Slate for structural headers and Slate for functional UI labels, ensuring the interface remains distinct from the novel content itself.

## Typography
This design system employs a dual-typeface strategy to distinguish between **Interacting** and **Reading**.

1.  **UI & Navigation (Inter):** A neutral, highly legible sans-serif used for buttons, menus, sidebars, and metadata. It conveys efficiency and modern technical capability.
2.  **The Reading Experience (Merriweather):** A high-readability serif typeface designed specifically for screens. It is used exclusively for the source and translated novel text. The generous line height (1.7x+) and optimized font size (18px) are calibrated to prevent eye fatigue during extended editing sessions.

Hierarchies are reinforced through weight and letter spacing rather than just size, maintaining a compact UI that maximizes the available screen estate for the split-pane translator.

## Layout & Spacing
The system uses a **Fixed-Fluid Hybrid** layout. The sidebar remains fixed at 260px, while the main workspace utilizes a split-pane model that divides the remaining horizontal space 50/50 between source and target text.

- **Rhythm:** An 8px grid system governs all components, ensuring mathematical harmony.
- **Margins:** A standard 24px margin exists around the main application container. 
- **The Reader View:** Requires increased horizontal padding (32px - 48px) within the panes to create "breathing room" for the text, mimicking the margins of a printed book.
- **Responsive Behavior:** On tablet, the sidebar collapses into a hamburger menu. On mobile, the split-pane shifts to a vertical stack or a tabbed view to maintain text legibility.

## Elevation & Depth
Elevation is communicated through **Tonal Layering** and **Subtle Ambient Shadows**. 

- **Level 0 (Background):** The `#F9FAFB` base layer.
- **Level 1 (Panels):** Sidebars and secondary panels use a thin 1px border (`#E5E7EB`) with no shadow to feel integrated into the application structure.
- **Level 2 (Active Workspace):** The main translation cards or text areas use a very soft, diffused shadow (0px 4px 12px rgba(0,0,0,0.03)) to appear slightly lifted above the background.
- **Level 3 (Overlays):** Modals and dropdowns use a more pronounced shadow (0px 10px 25px rgba(0,0,0,0.08)) to indicate temporary dominance over the workspace.

Depth is also used to indicate "Focus Mode"—when a user is editing a specific paragraph, surrounding segments should dim slightly in opacity rather than using heavy shadows.

## Shapes
The design system follows a **Rounded** aesthetic (8px/0.5rem base) to soften the technical nature of an AI tool and make the workspace feel more inviting.

- **Primary Components:** Buttons, input fields, and small cards use the base 8px radius.
- **Large Containers:** Main editor panes and modals use `rounded-lg` (16px) to define distinct sections of the app.
- **Status Badges:** Use a fully rounded "pill" shape to distinguish them from interactive buttons.
- **Selection Highlights:** Paragraph-level highlights should use a subtle 4px radius to feel precise yet integrated with the text flow.

## Components
### Buttons & Actions
Primary buttons use the Seed Color (`#3B82F6`) with white text. Ghost buttons (border only) are preferred for secondary actions like "Export" or "View History" to keep the focus on the translation.

### Progress & Status
- **Progress Bars:** Use a thin (4px) height for background tasks, expanding to 8px only for primary file uploads/translations.
- **Status Badges:** Small, uppercase labels with a light tinted background of their respective status color (e.g., Translating: Amber background @ 10% opacity with Amber text).

### Split-Pane Editor
The core component. A vertical divider sits between the two panes. On hover, the divider shows a subtle blue handle, indicating it is draggable to adjust the width of the source vs. target text.

### Tabs (Reader/Glossary/Relations)
Utilize an "Underline" style for top-level navigation. The active tab is indicated by a 2px solid blue bottom border and a weight change to Semi-Bold.

### Input Fields & Search
Clean, white backgrounds with a 1px slate border. Focus states must use a 2px blue ring with 20% opacity to clearly indicate the active text field.

### Modern Sidebar
A minimalist vertical nav with thin borders. Icons should be Lucide-style (2px stroke) with labels in `ui-medium` typography. Active states are indicated by a subtle background tint or a vertical "pill" indicator on the left edge.