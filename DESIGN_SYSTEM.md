# ArtFlow Design System & UI Guidelines

## 🎨 Color Palette

### Primary Colors
- **Primary Red**: `#B71B1B` 
  - Used for: CTA buttons, active states, badges, highlights
  - Secondary shades: `#8F1414` (darker), `#DAAF1F` (warm variant)

- **Gold/Secondary**: `#E3BC2D`
  - Used for: Accents, featured items, notifications

### Neutral Colors
- **Background**: `#FFF6ED` (Warm cream - main scaffold background)
- **Surface**: `#FFFFFF` (White - card and input backgrounds)
- **Foreground/Text**: `#161616` (Almost black - primary text)

### Semantic Colors
- **Error**: `#9A1D1D` (Deep red for errors)
- **Success**: `#166534` (Green for confirmations)
- **Warning**: Various opacity levels of primary

### Opacity Variants
- **Low Visibility**: `Colors.black26` (placeholders, hints)
- **Medium Visibility**: `Colors.black54` (secondary text)
- **High Visibility**: `Colors.black87` (primary text)

---

## 🔤 Typography System

### Font Families
- **Headings**: `Playfair Display`
  - Weight: 700 (bold)
  - Used for: H1, H2, H3, Titles
  - Character: Elegant, distinctive

- **Body Text**: `Inter`
  - Weight: 400 (regular) or 600 (semibold)
  - Used for: Paragraph text, labels, UI copy

### Type Scale
```
Headline Large (H1):
  - Size: 30px
  - Weight: 700
  - Color: #161616
  - Use: Page titles, main headings

Headline Medium (H2):
  - Size: 26px
  - Weight: 700
  - Color: #161616
  - Use: Section headings

Headline Small (H3):
  - Size: 22px
  - Weight: 700
  - Color: #161616
  - Use: Subsection headings

Title Large:
  - Size: 20px
  - Weight: 600
  - Color: #161616
  - Use: Card titles, major UI elements

Title Medium:
  - Size: 16px
  - Weight: 600
  - Color: #161616
  - Use: Input labels, button text

Body Large:
  - Size: 16px
  - Weight: 400
  - Color: #161616
  - Use: Paragraph text, descriptions

Body Medium (Default):
  - Size: 14px
  - Weight: 400
  - Color: #161616
  - Use: Standard body text

Body Small:
  - Size: 12px
  - Weight: 400
  - Color: #666666 (secondary text)
  - Use: Captions, helper text
```

---

## 🎛️ Component Specifications

### Buttons

#### Filled Button (Primary CTA)
```
Background: #B71B1B (primary)
Text Color: #FFFFFF (white)
Padding: 16px vertical, 24px horizontal
Height: 52px (for touch targets)
Border Radius: 12px
Font: Title Medium, Bold
State Variations:
  - Enabled: Full opacity, shadow
  - Disabled: Reduced opacity (0.5)
  - Pressed: Slightly darker background
```

#### Outlined Button (Secondary)
```
Background: Transparent
Border: 1.5px solid #B71B1B
Text Color: #B71B1B
Padding: Same as filled
Height: 52px
Border Radius: 12px
Font: Title Medium, Bold
```

#### Text Button
```
Background: Transparent
Text Color: #666666 (for secondary), #B71B1B (for primary actions)
Padding: 8px horizontal
No border
Font: Title Small
Used for: Skip, Cancel, Secondary actions
```

### Input Fields

#### Text Input
```
Background: #FFFFFF (white)
Border: 1px solid #E4D8CB (default state)
Border (Focused): 1.5px solid #B71B1B
Border Radius: 12px
Padding: 14px vertical, 16px horizontal
Height: ~48px
Font: Body Medium

Features:
  - Prefix icon support (28px icon)
  - Suffix icon support (toggle, clear)
  - Placeholder text: #000000 with opacity 0.26
  - Label: Title Small, 600 weight
  - Spacing between label and field: 8px
```

### Cards

```
Background: #FFFFFF
Border Radius: 14-20px (varying based on prominence)
Padding: 14-16px
Shadow: 
  - Blur: 8-18px
  - Offset: Y +4 to +10px
  - Opacity: 0.05-0.15
Used for: Feature highlights, artist cards, artwork cards
```

### Chips (Filter/Selection)

```
Selected State:
  - Background: Primary with 0.2 opacity (#B71B1B with 20% opacity)
  - Border: 1.5px solid #B71B1B
  - Text: #161616

Unselected State:
  - Background: #FFFFFF
  - Border: 1px solid #E4D8CB
  - Text: #161616
```

---

## 📏 Spacing System

### Base Unit: 8px

#### Standard Spacing Values
```
4px    - Minimal spacing (rarely used)
8px    - Tight spacing (between inline elements)
12px   - Small spacing (field separators)
16px   - Standard spacing (most common)
20px   - Medium spacing (between sections)
24px   - Large spacing (major sections)
32px   - Extra large (before CTA sections)
40px   - Huge spacing (between major sections)
```

#### Application
```
Page Padding: 24px (horizontal), 24px (vertical)
Section Gap: 20px
Input Group Gap: 12px
Button Gap: 12px (between buttons)
List Item Gap: 8-10px
Header/Title + Description Gap: 8px
Description + Content Gap: 16-20px
```

---

## 🌈 Gradient Usage

### Primary Gradient (Splash/Hero Sections)
```
Colors: #8F1414 → #B71B1B → #DAAF1F
Direction: Top-left to bottom-right
Usage: Splash screen, hero sections, high-impact areas
```

### Subtle Gradient (Form/Content Areas)
```
Colors: #FFF6ED → #FAEDC (with 0.6 opacity end)
Direction: Top to bottom
Usage: Form backgrounds, onboarding screens, content areas
```

---

## ✨ Visual Hierarchy Implementation

### Color Hierarchy
1. **Primary Actions**: #B71B1B (filled buttons, active states)
2. **Secondary Actions**: White with #B71B1B border (outlined buttons)
3. **Tertiary Actions**: Text only, #666666 color
4. **Disabled States**: Reduced opacity (0.5)

### Size Hierarchy
1. **Headlines**: 26-30px (H1, H2)
2. **Subheadings**: 20-22px (H3, titles)
3. **Body**: 14-16px (standard text)
4. **Captions**: 12px (helper text)

### Weight Hierarchy
1. **Strong**: Weight 700 (headlines)
2. **Medium**: Weight 600 (titles, labels)
3. **Regular**: Weight 400 (body text)

---

## 📱 Responsive Breakpoints

```
Mobile: < 600px
Tablet: 600px - 1024px
Desktop: > 1024px

Current Implementation: Optimized for mobile-first (primary platform: Flutter Mobile)
```

---

## 🎯 Form Design Patterns

### Single Input Section
```
Label (Title Small, Weight 600)
    ↓ 8px gap
Input Field
    ↓ 8px gap
Helper Text / Error Message (Body Small, gray)
```

### Multiple Inputs
```
Section Title (Headline Small)
    ↓ 12px gap
Input 1
    ↓ 12px gap
Input 2
    ↓ 12px gap
Input 3
    ↓ 20px gap
Next Section / Button
```

### Form Layout Best Practices
✅ Left-align labels
✅ Use icons for visual guidance
✅ Include helper/hint text for clarity
✅ Group related fields
✅ Use consistent spacing (12px between inputs)
✅ Place primary CTA at bottom
✅ Allow skip/cancel option
❌ Don't exceed 50% of screen width on mobile
❌ Don't use vague placeholders as only labels

---

## 🎬 Animation Guidelines

### Transitions
- **Standard**: 250-300ms (e.g., button hover, state changes)
- **Page Transitions**: 300-500ms (e.g., navigation)
- **Entrance Animations**: 500-800ms (e.g., splash logo)

### Curves
- **easeInOut**: Standard transitions
- **easeOutBack**: Entrance animations (logo bounce)
- **easeIn**: Fade outs

### Duration Examples
```
Splash Logo Animation: 1500ms (scale + fade)
Page Navigation: 300ms
Button Press Feedback: 200ms
Modal Slide In: 400ms
```

---

## 🌙 Dark Mode Considerations

Current: Light mode only
Future Implementation Guidelines:
```
Dark Mode Palette:
  - Background: #1A1A1A
  - Surface: #2C2C2C
  - Primary: #FF6B6B (lighter variant)
  - Text: #FFFFFF
  - Secondary Text: #CCCCCC

Apply: Use `Theme.of(context).brightness == Brightness.dark`
```

---

## ♿ Accessibility Guidelines

### Color Contrast
- Text on background: Minimum 4.5:1 (WCAG AA)
- Text on interactive elements: Minimum 4.5:1
- Large text (18pt+): Minimum 3:1

### Touch Targets
- Minimum: 48x48px (Material Design)
- Comfortable: 56-64px
- Current buttons: 52px height ✅

### Text Sizing
- Never disable text scaling
- Use relative font sizes where possible
- Test with 200% text scaling

### Labels & Hints
- Always provide labels for inputs
- Use semantic HTML/Material widgets
- Include error messages in accessibility tree

---

## 📚 Component Library

### Ready-Made Components in ArtFlow
- [x] `_FormField` - Consistent input field wrapper
- [x] `_FeatureCard` - Feature highlight card
- [x] `_StepIndicator` - Multi-step form indicator
- [x] `_InfoBox` - Information/warning box

### Custom Widgets to Build (Future)
- [ ] `ArtflowButton` - Consistent button wrapper
- [ ] `ArtflowInput` - Wrapped TextField with validation
- [ ] `ArtflowCard` - Consistent card component
- [ ] `ArtflowAppBar` - Branded app bar
- [ ] `ArtflowBottomNav` - Navigation component

---

**Design System Version**: 1.0
**Last Updated**: April 2026
**Status**: Production Ready
