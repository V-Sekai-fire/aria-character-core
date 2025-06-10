# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.CharacterGeneratorTest do
  use ExUnit.Case
  defp generate_character_id do
    UUID.uuid4()
  end

  @character_sliders %{
    "species" => %{
      type: "categorical",
      options: [
        "SPECIES_HUMANOID",
        "SPECIES_SEMI_HUMANOID",
        "SPECIES_HUMANOID_ROBOT_OR_CYBORG",
        "SPECIES_ANIMAL",
        "SPECIES_MONSTER",
        "SPECIES_OTHER"
      ],
      default: "SPECIES_SEMI_HUMANOID"
    },
    "emotion" => %{
      type: "categorical",
      options: [
        "EMOTION_NEUTRAL",
        "EMOTION_HAPPY",
        "EMOTION_SAD",
        "EMOTION_ANGRY",
        "EMOTION_SURPRISED",
        "EMOTION_PLAYFUL",
        "EMOTION_CONFIDENT",
        "EMOTION_SHY",
        "EMOTION_MYSTERIOUS"
      ],
      default: "EMOTION_NEUTRAL"
    },
    "style_kei" => %{
      type: "categorical",
      options: [
        "STYLE_KEI_E_GIRL_E_BOY",
        "STYLE_KEI_ANIME",
        "STYLE_KEI_FURRY",
        "STYLE_KEI_ROBOTIC_CYBORG",
        "STYLE_KEI_CUTE_KAWAII",
        "STYLE_KEI_GOTHIC_DARK_FANTASY",
        "STYLE_KEI_SCI_FI_FUTURISTIC",
        "STYLE_KEI_STEAMPUNK",
        "STYLE_KEI_CASUAL_STREETWEAR"
      ],
      default: "STYLE_KEI_ANIME"
    },
    "color_palette" => %{
      type: "categorical",
      options: [
        "COLOR_PALETTE_VIBRANT_NEON",
        "COLOR_PALETTE_DARK_EDGY",
        "COLOR_PALETTE_PASTEL_SOFT",
        "COLOR_PALETTE_MONOCHROMATIC",
        "COLOR_PALETTE_CYBERPUNK_GLOW",
        "COLOR_PALETTE_METALLIC_CHROME",
        "COLOR_PALETTE_RAINBOW_SPECTRUM",
        "COLOR_PALETTE_ANIME_INSPIRED"
      ],
      default: "COLOR_PALETTE_ANIME_INSPIRED"
    },
    "key_motifs" => %{
      type: "categorical",
      options: [
        "KEY_MOTIFS_TECHWEAR_ELEMENTS",
        "KEY_MOTIFS_FANTASY_APPENDAGES",
        "KEY_MOTIFS_GLOWING_ACCENTS",
        "KEY_MOTIFS_CYBERNETIC_IMPLANTS",
        "KEY_MOTIFS_ANIMAL_FEATURES",
        "KEY_MOTIFS_GOTHIC_DETAILS",
        "KEY_MOTIFS_SCI_FI_VISORS",
        "KEY_MOTIFS_CUTE_ACCESSORIES",
        "KEY_MOTIFS_STREET_STYLE_GRAPHICS",
        "KEY_MOTIFS_MAGICAL_AURAS"
      ],
      default: "KEY_MOTIFS_GLOWING_ACCENTS"
    },
    "layering_style" => %{
      type: "categorical",
      options: [
        "LAYERING_STYLE_MULTI_LAYERED_STREETWEAR",
        "LAYERING_STYLE_FORM_FITTING_BODYSUIT",
        "LAYERING_STYLE_FLOWING_GARMENTS",
        "LAYERING_STYLE_IDOL_POPSTAR_OUTFIT",
        "LAYERING_STYLE_TACTICAL_GEAR",
        "LAYERING_STYLE_MINIMALIST_SLEEK",
        "LAYERING_STYLE_KEMONO_FURRY_STYLE",
        "LAYERING_STYLE_FRAGMENTED_PIECES"
      ],
      default: "LAYERING_STYLE_MULTI_LAYERED_STREETWEAR"
    },
    "detail_level" => %{
      type: "numeric",
      min: 1,
      max: 10,
      default: 7
    },
    "age" => %{
      type: "categorical",
      options: ["AGE_YOUNG_ADULT", "AGE_ADULT"],
      default: "AGE_ADULT"
    },
    "avatar_gender_appearance" => %{
      type: "categorical",
      options: [
        "AVATAR_GENDER_APPEARANCE_MASCULINE",
        "AVATAR_GENDER_APPEARANCE_FEMININE",
        "AVATAR_GENDER_APPEARANCE_OTHER"
      ],
      default: "AVATAR_GENDER_APPEARANCE_FEMININE"
    },
    "humanoid_archetype" => %{
      type: "categorical",
      options: [
        "HUMANOID_ARCHETYPE_HUMAN_FEATURED",
        "HUMANOID_ARCHETYPE_FOX_PERSON",
        "HUMANOID_ARCHETYPE_CAT_PERSON",
        "HUMANOID_ARCHETYPE_OTHER_KEMONOMIMI"
      ],
      default: "HUMANOID_ARCHETYPE_HUMAN_FEATURED"
    },
    "kemonomimi_animal_ears_presence" => %{
      type: "categorical",
      options: ["KEMONOMIMI_EARS_TRUE", "KEMONOMIMI_EARS_FALSE"],
      default: "KEMONOMIMI_EARS_FALSE"
    },
    "kemonomimi_animal_tail_presence" => %{
      type: "categorical",
      options: ["KEMONOMIMI_TAIL_TRUE", "KEMONOMIMI_TAIL_FALSE"],
      default: "KEMONOMIMI_TAIL_FALSE"
    },
    "kemonomimi_animal_tail_style" => %{
      type: "categorical",
      options: [
        "KEMONOMIMI_TAIL_STYLE_FLUFFY",
        "KEMONOMIMI_TAIL_STYLE_SLEEK",
        "KEMONOMIMI_TAIL_STYLE_SHORT_BOB",
        "KEMONOMIMI_TAIL_STYLE_LONG_FLOWING",
        "KEMONOMIMI_TAIL_STYLE_SEGMENTED_TECH"
      ],
      default: "KEMONOMIMI_TAIL_STYLE_FLUFFY"
    },
    # Class: Facial Characteristics
    "face_style" => %{
      type: "categorical",
      options: [
        "FACE_STYLE_ANIME_SOFT",
        "FACE_STYLE_ANIME_SHARP_MATURE",
        "FACE_STYLE_STYLIZED_NON_ANIME"
      ],
      default: "FACE_STYLE_ANIME_SOFT"
    },
    # Class: Appendages
    "hands_style" => %{
      type: "categorical",
      options: [
        "HANDS_STYLE_NORMAL_HUMAN",
        "HANDS_STYLE_SUBTLY_STYLIZED"
      ],
      default: "HANDS_STYLE_NORMAL_HUMAN"
    },
    # Phylum: Overall Style & Theme
    "primary_theme" => %{
      type: "categorical",
      options: [
        "PRIMARY_THEME_FANTASY_EAST_ASIAN",
        "PRIMARY_THEME_CYBERPREP_TECHWEAR",
        "PRIMARY_THEME_PASTEL_CYBER",
        "PRIMARY_THEME_TRADITIONAL_SHRINE_MAIDEN",
        "PRIMARY_THEME_CASUAL_TECH_STREETWEAR",
        "PRIMARY_THEME_MORI_KEI_NATURALIST"
      ],
      default: "PRIMARY_THEME_CYBERPREP_TECHWEAR"
    },
    "rendering_style" => %{
      type: "categorical",
      options: [
        "RENDERING_STYLE_TOON_SHADED",
        "RENDERING_STYLE_PAINTERLY_STYLIZED_3D",
        "RENDERING_STYLE_PIXEL_ART_TEXTURE_3D",
        "RENDERING_STYLE_VOXEL_ART"
      ],
      default: "RENDERING_STYLE_PAINTERLY_STYLIZED_3D"
    },
    "modesty_level" => %{
      type: "categorical",
      options: [
        "MODESTY_TWITCH_APPROPRIATE_FULL_COVERAGE",
        "MODESTY_MODERATE_COVERAGE",
        "MODESTY_STYLIZED_REVEALING"
      ],
      default: "MODESTY_TWITCH_APPROPRIATE_FULL_COVERAGE"
    },
    "geometric_complexity" => %{
      type: "categorical",
      options: [
        "GEOMETRIC_COMPLEXITY_GAME_OPTIMIZED",
        "GEOMETRIC_COMPLEXITY_HIGH_DETAIL"
      ],
      default: "GEOMETRIC_COMPLEXITY_GAME_OPTIMIZED"
    },
    # Phylum: Attire System
    "headwear_item" => %{
      type: "categorical",
      options: [
        "HEADWEAR_NONE",
        "HEADWEAR_HOOD",
        "HEADWEAR_TECH_VISOR_HEADSET_GOGGLES",
        "HEADWEAR_FANTASY_HEADDRESS_ORNAMENTS",
        "HEADWEAR_ANIMAL_THEMED_HOOD",
        "HEADWEAR_BEANIE_CAP_HAT"
      ],
      default: "HEADWEAR_NONE"
    },
    "outerwear_item" => %{
      type: "categorical",
      options: [
        "OUTERWEAR_NONE",
        "OUTERWEAR_SHAWL_CAPELET",
        "OUTERWEAR_JACKET_TECHWEAR",
        "OUTERWEAR_JACKET_CASUAL_STREETWEAR",
        "OUTERWEAR_HAORI",
        "OUTERWEAR_VEST"
      ],
      default: "OUTERWEAR_NONE"
    },
    "outerwear_style" => %{
      type: "categorical",
      options: [
        "OUTERWEAR_STYLE_PROMINENT_FLOWING",
        "OUTERWEAR_STYLE_SLEEK_FITTED",
        "OUTERWEAR_STYLE_ASYMMETRICAL_CUT",
        "OUTERWEAR_STYLE_HOODED_VARIANT"
      ],
      default: "OUTERWEAR_STYLE_PROMINENT_FLOWING"
    },
    "top_garment" => %{
      type: "categorical",
      options: [
        "TOP_GARMENT_KIMONO_LIKE",
        "TOP_GARMENT_FUTURISTIC_BODYSUIT",
        "TOP_GARMENT_CASUAL_TOP",
        "TOP_GARMENT_TRADITIONAL_BLOUSE_SHIRT"
      ],
      default: "TOP_GARMENT_CASUAL_TOP"
    },
    "lower_garment" => %{
      type: "categorical",
      options: [
        "LOWER_GARMENT_FANTASY_PANTS",
        "LOWER_GARMENT_CYBERPREP_CARGO_PANTS",
        "LOWER_GARMENT_LEGGINGS_TIGHTS",
        "LOWER_GARMENT_SKIRT"
      ],
      default: "LOWER_GARMENT_CYBERPREP_CARGO_PANTS"
    },
    "lower_garment_skirt_style" => %{
      type: "categorical",
      options: [
        "SKIRT_STYLE_SHORT_SPATS_BLOOMERS",
        "SKIRT_STYLE_MID_LENGTH",
        "SKIRT_STYLE_LONG_FLOWING",
        "SKIRT_STYLE_LAYERED_OVER_PANTS"
      ],
      default: "SKIRT_STYLE_MID_LENGTH"
    },
    "waist_accent" => %{
      type: "categorical",
      options: [
        "WAIST_ACCENT_NONE",
        "WAIST_ACCENT_DECORATIVE_SASHES_OBI",
        "WAIST_ACCENT_TACTICAL_BELTS_HARNESS",
        "WAIST_ACCENT_SIMPLE_BELT"
      ],
      default: "WAIST_ACCENT_NONE"
    },
    "footwear_item" => %{
      type: "categorical",
      options: [
        "FOOTWEAR_FANTASY_TRADITIONAL",
        "FOOTWEAR_TECH_RUNNERS_SNEAKERS",
        "FOOTWEAR_PRACTICAL_COMBAT_BOOTS",
        "FOOTWEAR_CASUAL_SHOES"
      ],
      default: "FOOTWEAR_TECH_RUNNERS_SNEAKERS"
    },
    "footwear_cute_appearance" => %{
      type: "categorical",
      options: ["FOOTWEAR_CUTE_TRUE", "FOOTWEAR_CUTE_FALSE"],
      default: "FOOTWEAR_CUTE_FALSE"
    },
    "footwear_comfortable_appearance" => %{
      type: "categorical",
      options: ["FOOTWEAR_COMFORTABLE_TRUE", "FOOTWEAR_COMFORTABLE_FALSE"],
      default: "FOOTWEAR_COMFORTABLE_TRUE"
    },
    "legwear_accessories_presence" => %{
      type: "categorical",
      options: ["LEGWEAR_ACCESSORIES_TRUE", "LEGWEAR_ACCESSORIES_FALSE"],
      default: "LEGWEAR_ACCESSORIES_FALSE"
    },
    "legwear_style" => %{
      type: "categorical",
      options: [
        "LEGWEAR_STYLE_TABI_SOCKS",
        "LEGWEAR_STYLE_KNEE_HIGH_SOCKS_LEGWARMERS",
        "LEGWEAR_STYLE_ANKLE_SOCKS",
        "LEGWEAR_STYLE_THIGH_HIGH_HOSIERY",
        "LEGWEAR_STYLE_PATTERNED_HOSIERY"
      ],
      default: "LEGWEAR_STYLE_KNEE_HIGH_SOCKS_LEGWARMERS"
    },
    # Phylum: Color & Texture
    "color_palette_preset" => %{
      type: "categorical",
      options: [
        "COLOR_PALETTE_PRESET_BEIGE_BLUE_FANTASY",
        "COLOR_PALETTE_PRESET_MINT_LAVENDER_PASTEL_CYBER",
        "COLOR_PALETTE_PRESET_WHITE_RED_BLACK_TRADITIONAL",
        "COLOR_PALETTE_PRESET_TAN_BLUE_ORANGE_TECHWEAR",
        "COLOR_PALETTE_PRESET_MONOCHROMATIC_WITH_ACCENT",
        "COLOR_PALETTE_PRESET_CUSTOM"
      ],
      default: "COLOR_PALETTE_PRESET_MINT_LAVENDER_PASTEL_CYBER"
    },
    "pattern_theme" => %{
      type: "categorical",
      options: [
        "PATTERN_THEME_TRADITIONAL_GEOMETRIC_EAST_ASIAN",
        "PATTERN_THEME_CYBER_TECH",
        "PATTERN_THEME_FLORAL_STYLIZED",
        "PATTERN_THEME_MYSTICAL_SYMBOLS_RUNES",
        "PATTERN_THEME_CUTE_WHIMSICAL_ICONS",
        "PATTERN_THEME_ABSTRACT_MODERN_GEOMETRIC",
        "PATTERN_THEME_NONE"
      ],
      default: "PATTERN_THEME_NONE"
    },
    # Phylum: Thematic Embellishments - Class: Fantasy Elements
    "fantasy_magical_talismans_presence" => %{
      type: "categorical",
      options: ["FANTASY_TALISMANS_TRUE", "FANTASY_TALISMANS_FALSE"],
      default: "FANTASY_TALISMANS_FALSE"
    },
    "fantasy_magical_talismans_type" => %{
      type: "categorical",
      options: [
        "FANTASY_TALISMAN_TYPE_CHARM_OMAMORI",
        "FANTASY_TALISMAN_TYPE_PENDANT_NECKLACE",
        "FANTASY_TALISMAN_TYPE_OFUDA_TAG",
        "FANTASY_TALISMAN_TYPE_GLOWING_ORB_CRYSTAL",
        "FANTASY_TALISMAN_TYPE_RUNESTONES"
      ],
      default: "FANTASY_TALISMAN_TYPE_CHARM_OMAMORI"
    },
    "fantasy_magical_effect_style" => %{
      type: "categorical",
      options: [
        "FANTASY_EFFECT_GLOWING_RUNES_SYMBOLS",
        "FANTASY_EFFECT_SOFT_AURA_SHIMMER",
        "FANTASY_EFFECT_LUMINOUS_EMBROIDERY_THREADS",
        "FANTASY_EFFECT_FLOATING_SIGILS_PARTICLES"
      ],
      default: "FANTASY_EFFECT_SOFT_AURA_SHIMMER"
    },
    # Class: Cyberprep/Techwear Elements
    "cyber_visible_cybernetics_presence" => %{
      type: "categorical",
      options: ["CYBER_CYBERNETICS_TRUE", "CYBER_CYBERNETICS_FALSE"],
      default: "CYBER_CYBERNETICS_FALSE"
    },
    "cyber_visible_cybernetics_placement" => %{
      type: "categorical",
      options: [
        "CYBERNETICS_PLACEMENT_EYE_AUGMENT_VISOR",
        "CYBERNETICS_PLACEMENT_ARM_LEG_PROSTHETIC",
        "CYBERNETICS_PLACEMENT_INTERFACE_PORTS_SOCKETS",
        "CYBERNETICS_PLACEMENT_SPINAL_EXOSKELETAL_ACCENTS"
      ],
      default: "CYBERNETICS_PLACEMENT_EYE_AUGMENT_VISOR"
    },
    "cyber_tech_accessories_presence" => %{
      type: "categorical",
      options: ["CYBER_TECH_ACCESSORIES_TRUE", "CYBER_TECH_ACCESSORIES_FALSE"],
      default: "CYBER_TECH_ACCESSORIES_FALSE"
    },
    "cyber_tech_accessories_type" => %{
      type: "categorical",
      options: [
        "CYBER_ACCESSORY_INTEGRATED_VISOR_GOGGLES",
        "CYBER_ACCESSORY_HOLOGRAPHIC_EARPIECE_HEADPHONES",
        "CYBER_ACCESSORY_DATA_POUCHES_CANISTERS",
        "CYBER_ACCESSORY_UTILITY_GAUNTLETS"
      ],
      default: "CYBER_ACCESSORY_INTEGRATED_VISOR_GOGGLES"
    },
    "traditional_ritual_items_presence" => %{
      type: "categorical",
      options: ["TRADITIONAL_RITUAL_ITEMS_TRUE", "TRADITIONAL_RITUAL_ITEMS_FALSE"],
      default: "TRADITIONAL_RITUAL_ITEMS_FALSE"
    },
    "traditional_ritual_items_type" => %{
      type: "categorical",
      options: [
        "TRADITIONAL_RITUAL_ITEM_GOHEI_WAND",
        "TRADITIONAL_RITUAL_ITEM_SUZU_BELL_RATTLE",
        "TRADITIONAL_RITUAL_ITEM_CEREMONIAL_FAN",
        "TRADITIONAL_RITUAL_ITEM_PRAYER_BEADS"
      ],
      default: "TRADITIONAL_RITUAL_ITEM_GOHEI_WAND"
    },
    "traditional_large_bows_presence" => %{
      type: "categorical",
      options: ["TRADITIONAL_LARGE_BOWS_TRUE", "TRADITIONAL_LARGE_BOWS_FALSE"],
      default: "TRADITIONAL_LARGE_BOWS_FALSE"
    },
    "traditional_kanzashi_presence" => %{
      type: "categorical",
      options: ["TRADITIONAL_KANZASHI_TRUE", "TRADITIONAL_KANZASHI_FALSE"],
      default: "TRADITIONAL_KANZASHI_FALSE"
    }
  }

  # Slider weights map (ported from Python op_complex_randomize_sliders)
  @slider_weights %{
    "species" => [0.35, 0.54, 0.02, 0.02, 0.01, 0.06],
    "avatar_gender_appearance" => [0.17, 0.72, 0.11],
    "emotion" => [0.2, 0.15, 0.05, 0.05, 0.1, 0.2, 0.15, 0.05, 0.05],
    "style_kei" => [0.2, 0.25, 0.15, 0.05, 0.15, 0.05, 0.05, 0.05, 0.05],
    "color_palette" => [0.15, 0.2, 0.15, 0.1, 0.1, 0.05, 0.05, 0.2],
    "key_motifs" => [0.1, 0.15, 0.2, 0.05, 0.15, 0.05, 0.05, 0.1, 0.05, 0.1],
    "layering_style" => [0.25, 0.15, 0.05, 0.1, 0.05, 0.1, 0.25, 0.05],
    "age" => [0.4, 0.6],
    # Additional weights for categorical sliders
    "species_base_type" => [0.4, 0.3, 0.1, 0.1, 0.1],
    "humanoid_archetype" => [0.5, 0.25, 0.15, 0.1],
    "kemonomimi_animal_ears_presence" => [0.3, 0.7],
    "kemonomimi_animal_tail_presence" => [0.4, 0.6],
    "kemonomimi_animal_tail_style" => [0.3, 0.2, 0.2, 0.2, 0.1],
    "face_style" => [0.5, 0.3, 0.2],
    "hands_style" => [0.7, 0.3],
    "primary_theme" => [0.25, 0.25, 0.15, 0.15, 0.1, 0.1],
    "rendering_style" => [0.4, 0.3, 0.2, 0.1],
    "modesty_level" => [0.6, 0.3, 0.1],
    "geometric_complexity" => [0.8, 0.2],
    "headwear_item" => [0.3, 0.15, 0.15, 0.15, 0.15, 0.1],
    "outerwear_item" => [0.2, 0.15, 0.15, 0.15, 0.15, 0.2],
    "outerwear_style" => [0.3, 0.25, 0.25, 0.2],
    "top_garment" => [0.4, 0.2, 0.2, 0.2],
    "lower_garment" => [0.25, 0.25, 0.25, 0.25],
    "lower_garment_skirt_style" => [0.3, 0.4, 0.2, 0.1],
    "waist_accent" => [0.4, 0.2, 0.2, 0.2],
    "footwear_item" => [0.25, 0.35, 0.25, 0.15],
    "footwear_cute_appearance" => [0.3, 0.7],
    "footwear_comfortable_appearance" => [0.8, 0.2],
    "legwear_accessories_presence" => [0.2, 0.8],
    "legwear_style" => [0.15, 0.35, 0.2, 0.2, 0.1],
    "color_palette_preset" => [0.15, 0.25, 0.15, 0.15, 0.15, 0.15],
    "pattern_theme" => [0.1, 0.1, 0.15, 0.1, 0.15, 0.1, 0.3],
    "fantasy_magical_talismans_presence" => [0.3, 0.7],
    "fantasy_magical_talismans_type" => [0.3, 0.25, 0.2, 0.15, 0.1],
    "fantasy_magical_effect_style" => [0.25, 0.35, 0.25, 0.15],
    "cyber_visible_cybernetics_presence" => [0.2, 0.8],
    "cyber_visible_cybernetics_placement" => [0.4, 0.3, 0.2, 0.1],
    "cyber_tech_accessories_presence" => [0.25, 0.75],
    "cyber_tech_accessories_type" => [0.35, 0.25, 0.25, 0.15],
    "traditional_ritual_items_presence" => [0.2, 0.8],
    "traditional_ritual_items_type" => [0.3, 0.25, 0.25, 0.2],
    "traditional_large_bows_presence" => [0.3, 0.7],
    "traditional_kanzashi_presence" => [0.25, 0.75]
  }

  # Option descriptions data (ported from Python OPTION_DESCRIPTIONS_DATA)
  @option_descriptions %{
    "SPECIES_HUMANOID" => "A bipedal character with human-like features, often the baseline for many avatars.",
    "SPECIES_SEMI_HUMANOID" => "Primarily human-like but with significant non-human traits such as animal ears, tails, or unique skin textures (semi-humanoid).",
    "SPECIES_HUMANOID_ROBOT_OR_CYBORG" => "A character that is either fully mechanical or a blend of human and machine, featuring cybernetic enhancements.",
    "SPECIES_ANIMAL" => "A character based on real-world or fantastical animals, often anthropomorphic to varying degrees.",
    "SPECIES_MONSTER" => "A creature of fantasy or horror, which can range from grotesque to imposing or even cute, defying typical humanoid forms.",
    "SPECIES_OTHER" => "Avatars that don't fit neatly into the above categories, including abstract forms, mythical beings not otherwise covered, or unique original concepts.",
    "EMOTION_NEUTRAL" => "A calm and composed facial expression, showing no strong emotion.",
    "EMOTION_HAPPY" => "A joyful expression, often characterized by a smile and bright eyes.",
    "EMOTION_SAD" => "An expression of sorrow or unhappiness, perhaps with downcast eyes or a frown.",
    "EMOTION_ANGRY" => "A hostile expression, possibly with furrowed brows and a tense jaw.",
    "EMOTION_SURPRISED" => "An expression of astonishment, with wide eyes and an open mouth.",
    "EMOTION_PLAYFUL" => "A lighthearted and mischievous expression, inviting interaction.",
    "EMOTION_CONFIDENT" => "An expression of self-assurance and poise.",
    "EMOTION_SHY" => "A reserved or timid expression, possibly with averted gaze.",
    "EMOTION_MYSTERIOUS" => "An enigmatic expression that hints at hidden knowledge or intentions.",
    "STYLE_KEI_E_GIRL_E_BOY" => "A style characterized by elements of emo, punk, and goth, often with dyed hair, chains, and layered clothing, popular in online communities.",
    "STYLE_KEI_ANIME" => "Inspired by Japanese animation, featuring distinct aesthetics like large expressive eyes, vibrant hair colors, and often stylized outfits.",
    "STYLE_KEI_FURRY" => "Avatars representing anthropomorphic animals, with a wide range of species and artistic interpretations.",
    "STYLE_KEI_ROBOTIC_CYBORG" => "Mechanical or partially mechanical beings, ranging from sleek futuristic designs to rugged industrial looks.",
    "STYLE_KEI_CUTE_KAWAII" => "An aesthetic emphasizing cuteness, with soft features, pastel colors, and charming accessories, originating from Japanese culture.",
    "STYLE_KEI_GOTHIC_DARK_FANTASY" => "A style drawing from gothic art and dark fantasy themes, often featuring dark colors, elaborate or tattered clothing, and mystical elements.",
    "STYLE_KEI_SCI_FI_FUTURISTIC" => "Characters designed with advanced technology, sleek lines, and elements suggesting a future setting.",
    "STYLE_KEI_STEAMPUNK" => "A retrofuturistic style blending Victorian aesthetics with steam-powered technology, often featuring gears, goggles, and brass elements.",
    "STYLE_KEI_CASUAL_STREETWEAR" => "Modern, everyday clothing styles, including hoodies, jeans, sneakers, and contemporary fashion trends.",
    "COLOR_PALETTE_VIBRANT_NEON" => "Bright, highly saturated colors, often with glowing neon accents that stand out.",
    "COLOR_PALETTE_DARK_EDGY" => "Dominated by blacks, grays, and deep jewel tones, creating a moody or rebellious feel.",
    "COLOR_PALETTE_PASTEL_SOFT" => "Light, desaturated colors like baby blue, pink, and lavender, giving a gentle and dreamy appearance.",
    "COLOR_PALETTE_MONOCHROMATIC" => "Utilizing shades, tints, and tones of a single color for a cohesive and sophisticated look.",
    "COLOR_PALETTE_CYBERPUNK_GLOW" => "A mix of dark backgrounds with bright, artificial-looking neon lights, typical of cyberpunk aesthetics.",
    "COLOR_PALETTE_METALLIC_CHROME" => "Colors that mimic metals like silver, gold, chrome, and bronze, often used for robotic or futuristic styles.",
    "COLOR_PALETTE_RAINBOW_SPECTRUM" => "Incorporating a wide array of colors from the rainbow, often in a vibrant and playful manner.",
    "COLOR_PALETTE_ANIME_INSPIRED" => "Color schemes commonly found in anime, which can range from naturalistic to highly stylized and vibrant.",
    "KEY_MOTIFS_TECHWEAR_ELEMENTS" => "Functional and futuristic clothing details like straps, buckles, utility pockets, and technical fabrics.",
    "KEY_MOTIFS_FANTASY_APPENDAGES" => "Non-human features like wings, horns, tails, or elven ears, adding a fantastical element.",
    "KEY_MOTIFS_GLOWING_ACCENTS" => "Luminous details on clothing or the body, such as light strips, glowing eyes, or magical auras.",
    "KEY_MOTIFS_CYBERNETIC_IMPLANTS" => "Visible mechanical or electronic enhancements integrated into the character's body.",
    "KEY_MOTIFS_ANIMAL_FEATURES" => "Traits borrowed from animals, such as fur patterns, whiskers, paws, or snouts, common in furry avatars.",
    "KEY_MOTIFS_GOTHIC_DETAILS" => "Elements like lace, corsets, dark jewelry, and symbols associated with gothic subculture or dark fantasy.",
    "KEY_MOTIFS_SCI_FI_VISORS" => "Futuristic eyewear, ranging from sleek data visors to protective helmets with illuminated displays.",
    "KEY_MOTIFS_CUTE_ACCESSORIES" => "Charming additions like bows, bells, plush toys, or whimsical hats that enhance a kawaii aesthetic.",
    "KEY_MOTIFS_STREET_STYLE_GRAPHICS" => "Bold logos, text, or artistic designs printed on clothing, typical of urban streetwear.",
    "KEY_MOTIFS_MAGICAL_AURAS" => "Ethereal glows, particle effects, or symbolic energy fields surrounding the character, indicating magical abilities.",
    "LAYERING_STYLE_MULTI_LAYERED_STREETWEAR" => "Multi-layered streetwear combining multiple pieces of casual clothing like hoodies, jackets, and t-shirts for a fashionable, urban look.",
    "LAYERING_STYLE_FORM_FITTING_BODYSUIT" => "A sleek, single-piece garment that conforms tightly to the body, often used for sci-fi or superhero styles.",
    "LAYERING_STYLE_FLOWING_GARMENTS" => "Loose and draped clothing such as robes, capes, or long skirts that create a sense of movement and elegance.",
    "LAYERING_STYLE_IDOL_POPSTAR_OUTFIT" => "Flashy and coordinated attire typical of performers, often featuring sequins, unique silhouettes, and thematic consistency.",
    "LAYERING_STYLE_TACTICAL_GEAR" => "Military-inspired or functional equipment like vests, harnesses, and utility belts, suggesting preparedness or combat readiness.",
    "LAYERING_STYLE_MINIMALIST_SLEEK" => "Simple, clean lines with minimal ornamentation, focusing on form and understated elegance.",
    "LAYERING_STYLE_KEMONO_FURRY_STYLE" => "Clothing and accessories specifically designed for or complementing anthropomorphic animal avatars.",
    "LAYERING_STYLE_FRAGMENTED_PIECES" => "An avant-garde style where clothing appears deconstructed, asymmetrical, or composed of detached elements.",
    "AGE_YOUNG_ADULT" => "A character appearing to be in their late teens to early twenties, often exuding youthfulness and energy.",
    "AGE_ADULT" => "A character appearing to be a mature individual, typically from mid-twenties onwards, conveying experience or established presence.",
    "AVATAR_GENDER_APPEARANCE_MASCULINE" => "An appearance characterized by features typically associated with male individuals.",
    "AVATAR_GENDER_APPEARANCE_FEMININE" => "An appearance characterized by features typically associated with female individuals.",
    "AVATAR_GENDER_APPEARANCE_OTHER" => "An appearance that is androgynous, non-binary, or otherwise does not strictly conform to typical masculine or feminine presentations.",
    "FOOTWEAR_CUTE_TRUE" => "Footwear designed with adorable and charming aesthetic elements, often featuring kawaii-inspired details, soft colors, or playful shapes.",
    "FOOTWEAR_CUTE_FALSE" => "Footwear with a more standard or practical design, without specifically cute or kawaii aesthetic elements.",
    # Physical Features
    "HANDS_STYLE_NORMAL_HUMAN" => "Standard human hands with natural proportions and skin texture.",
    "HANDS_STYLE_SUBTLY_STYLIZED" => "Hands with slight artistic stylization while maintaining realistic proportions.",
    "FACE_STYLE_ANIME_SOFT" => "Soft anime-inspired facial features with large expressive eyes and gentle contours.",
    "FACE_STYLE_ANIME_SHARP_MATURE" => "Sharp, mature anime-inspired facial features with defined angles and sophisticated expression.",
    "FACE_STYLE_STYLIZED_NON_ANIME" => "Stylized facial features that are not specifically anime-inspired.",
    # Species and Body Types
    "SPECIES_BASE_HUMANOID" => "A fundamentally human-like body structure and form.",
    "SPECIES_BASE_SEMI_HUMANOID" => "Primarily human structure with some non-human characteristics.",
    "SPECIES_BASE_ROBOTIC_CYBORG" => "Mechanical or partially mechanical body structure.",
    "SPECIES_BASE_ANIMAL" => "An animal-based character form with varying degrees of anthropomorphic features.",
    "SPECIES_BASE_OTHER" => "Non-standard body types that don't fit typical humanoid categories.",
    # Humanoid Archetypes
    "HUMANOID_ARCHETYPE_HUMAN_FEATURED" => "Standard human facial and body features without animal characteristics.",
    "HUMANOID_ARCHETYPE_CAT_PERSON" => "Human-like form with feline characteristics such as ears, tail, and facial features.",
    "HUMANOID_ARCHETYPE_FOX_PERSON" => "Human-like form with fox characteristics such as ears, tail, and facial features.",
    "HUMANOID_ARCHETYPE_OTHER_KEMONOMIMI" => "Human-like form with animal characteristics from various species.",
    # Kemonomimi Features
    "KEMONOMIMI_EARS_TRUE" => "Visible animal ears as part of the character design.",
    "KEMONOMIMI_EARS_FALSE" => "No animal ears, standard human ear placement.",
    "KEMONOMIMI_TAIL_TRUE" => "Visible animal tail as part of the character design.",
    "KEMONOMIMI_TAIL_FALSE" => "No animal tail present.",
    "KEMONOMIMI_TAIL_STYLE_FLUFFY" => "A soft, fluffy tail typical of cats, foxes, or similar animals.",
    "KEMONOMIMI_TAIL_STYLE_SLEEK" => "A smooth, sleek tail design.",
    "KEMONOMIMI_TAIL_STYLE_SHORT_BOB" => "A short, bobbed tail that is compact and cute in appearance.",
    "KEMONOMIMI_TAIL_STYLE_LONG_FLOWING" => "A long and flowing animal tail.",
    "KEMONOMIMI_TAIL_STYLE_SEGMENTED_TECH" => "A mechanical or technological tail with segmented construction.",
    # Style and Theme
    "PRIMARY_THEME_CYBERPREP_TECHWEAR" => "A futuristic style combining cyberpunk aesthetics with practical technical wear.",
    "PRIMARY_THEME_PASTEL_CYBER" => "A softer cyberpunk aesthetic using pastel colors and cute elements.",
    "PRIMARY_THEME_FANTASY_EAST_ASIAN" => "A fantasy theme inspired by East Asian mythology, architecture, and traditional aesthetics.",
    "PRIMARY_THEME_TRADITIONAL_SHRINE_MAIDEN" => "A traditional Japanese shrine maiden theme featuring ceremonial robes, spiritual elements, and sacred aesthetics.",
    "PRIMARY_THEME_CASUAL_TECH_STREETWEAR" => "A modern urban style combining casual streetwear fashion with technological elements and accessories.",
    "PRIMARY_THEME_MORI_KEI_NATURALIST" => "A nature-inspired Japanese fashion style emphasizing forest and earth tones.",
    "RENDERING_STYLE_PAINTERLY_STYLIZED_3D" => "A 3D rendering style that mimics painted artwork with artistic stylization.",
    "RENDERING_STYLE_PIXEL_ART_TEXTURE_3D" => "3D rendering with pixel art-inspired textures and styling.",
    "RENDERING_STYLE_TOON_SHADED" => "A cartoon or toon-style 3D rendering with cell-shading and simplified lighting for an animated appearance.",
    "RENDERING_STYLE_VOXEL_ART" => "3D art style using voxel-based construction similar to Minecraft aesthetics.",
    "GEOMETRIC_COMPLEXITY_GAME_OPTIMIZED" => "Simplified geometry designed for optimal performance in games.",
    "GEOMETRIC_COMPLEXITY_HIGH_DETAIL" => "Complex, detailed geometry with intricate surface details.",
    "MODESTY_TWITCH_APPROPRIATE_FULL_COVERAGE" => "Clothing coverage appropriate for streaming platforms with full body coverage.",
    "MODESTY_MODERATE_COVERAGE" => "Balanced clothing coverage providing modest styling while maintaining visual appeal.",
    "MODESTY_STYLIZED_REVEALING" => "More revealing clothing styles while maintaining artistic stylization.",
    # Clothing and Attire
    "HEADWEAR_NONE" => "No headwear or head accessories.",
    "HEADWEAR_HOOD" => "A hood covering part or all of the head.",
    "HEADWEAR_TECH_VISOR_HEADSET_GOGGLES" => "High-tech eyewear including visors, headsets, or goggles with technological features.",
    "HEADWEAR_FANTASY_HEADDRESS_ORNAMENTS" => "Decorative fantasy headpieces including tiaras, circlets, ornamental headdresses, or magical crowns.",
    "HEADWEAR_ANIMAL_THEMED_HOOD" => "A hood designed with animal features such as ears, horns, or other creature-inspired elements.",
    "HEADWEAR_BEANIE_CAP_HAT" => "Various types of casual headwear including beanies, caps, or hats.",
    "OUTERWEAR_NONE" => "No outer garments or jackets.",
    "OUTERWEAR_SHAWL_CAPELET" => "A short, sleeveless cloak or cape worn over the shoulders, often decorative or ceremonial.",
    "OUTERWEAR_JACKET_CASUAL_STREETWEAR" => "Casual jackets typical of streetwear fashion.",
    "OUTERWEAR_JACKET_TECHWEAR" => "Technical or futuristic jackets with functional elements and modern styling.",
    "OUTERWEAR_HAORI" => "A traditional Japanese jacket or overcoat, often worn open and flowing.",
    "OUTERWEAR_VEST" => "A sleeveless outer garment worn over other clothing.",
    "OUTERWEAR_STYLE_PROMINENT_FLOWING" => "Outerwear with flowing, dramatic silhouettes.",
    "OUTERWEAR_STYLE_SLEEK_FITTED" => "Outerwear with a close-fitting, streamlined silhouette that emphasizes form and modern styling.",
    "OUTERWEAR_STYLE_ASYMMETRICAL_CUT" => "Outerwear featuring asymmetrical designs, uneven hemlines, or off-center closures for an avant-garde appearance.",
    "OUTERWEAR_STYLE_HOODED_VARIANT" => "Outerwear featuring an integrated hood.",
    "TOP_GARMENT_CASUAL_TOP" => "Casual upper body clothing such as t-shirts, hoodies, or casual shirts.",
    "TOP_GARMENT_FUTURISTIC_BODYSUIT" => "A sleek, form-fitting garment with technological enhancements and futuristic design elements.",
    "TOP_GARMENT_KIMONO_LIKE" => "Upper garments inspired by traditional Japanese kimono design.",
    "TOP_GARMENT_TRADITIONAL_BLOUSE_SHIRT" => "More formal or traditional upper body garments.",
    "LOWER_GARMENT_FANTASY_PANTS" => "Fantasy-inspired pants with mystical or traditional design elements.",
    "LOWER_GARMENT_CYBERPREP_CARGO_PANTS" => "Futuristic cargo pants with technical details and multiple pockets.",
    "LOWER_GARMENT_LEGGINGS_TIGHTS" => "Form-fitting leg coverings such as leggings or tights.",
    "LOWER_GARMENT_SKIRT" => "Various styles of skirts as lower body garments.",
    "SKIRT_STYLE_SHORT_SPATS_BLOOMERS" => "Short, gathered undergarments or shorts worn under skirts, often with a cute, sporty appearance.",
    "SKIRT_STYLE_MID_LENGTH" => "Skirts that fall to mid-thigh or knee length.",
    "SKIRT_STYLE_LONG_FLOWING" => "Long skirts with flowing, elegant movement.",
    "SKIRT_STYLE_LAYERED_OVER_PANTS" => "Skirts worn as an overlay on top of pants or leggings.",
    "WAIST_ACCENT_NONE" => "No special waist accessories or accents.",
    "WAIST_ACCENT_DECORATIVE_SASHES_OBI" => "Traditional decorative waist sashes or obi-style wrapping.",
    "WAIST_ACCENT_TACTICAL_BELTS_HARNESS" => "Functional or tactical-style belts and harness systems.",
    "WAIST_ACCENT_SIMPLE_BELT" => "Basic belt for practical or minimal aesthetic purposes.",
    "FOOTWEAR_FANTASY_TRADITIONAL" => "Fantasy-inspired or traditional-style footwear.",
    "FOOTWEAR_TECH_RUNNERS_SNEAKERS" => "Futuristic or technical-style running shoes and sneakers.",
    "FOOTWEAR_PRACTICAL_COMBAT_BOOTS" => "Sturdy, practical boots designed for durability and function.",
    "FOOTWEAR_CASUAL_SHOES" => "Everyday casual footwear for comfort and style.",
    "FOOTWEAR_COMFORTABLE_TRUE" => "Footwear designed with comfort and ergonomics as primary features.",
    "FOOTWEAR_COMFORTABLE_FALSE" => "Footwear that prioritizes style over comfort.",
    "LEGWEAR_ACCESSORIES_TRUE" => "Additional leg accessories such as garters, straps, or decorative elements.",
    "LEGWEAR_ACCESSORIES_FALSE" => "No additional leg accessories, clean and simple leg styling.",
    "LEGWEAR_STYLE_TABI_SOCKS" => "Traditional Japanese split-toe socks or tabi-inspired legwear.",
    "LEGWEAR_STYLE_KNEE_HIGH_SOCKS_LEGWARMERS" => "Knee-high socks, stockings, or leg warmers.",
    "LEGWEAR_STYLE_ANKLE_SOCKS" => "Short socks that end at or below the ankle.",
    "LEGWEAR_STYLE_THIGH_HIGH_HOSIERY" => "Stockings or socks that extend to thigh level.",
    "LEGWEAR_STYLE_PATTERNED_HOSIERY" => "Legwear featuring decorative patterns or designs.",
    # Colors and Patterns
    "COLOR_PALETTE_PRESET_BEIGE_BLUE_FANTASY" => "A fantasy-inspired color scheme using beige and blue tones.",
    "COLOR_PALETTE_PRESET_MINT_LAVENDER_PASTEL_CYBER" => "Soft cyber aesthetic using mint green and lavender pastels.",
    "COLOR_PALETTE_PRESET_WHITE_RED_BLACK_TRADITIONAL" => "Classic traditional color scheme with white, red, and black.",
    "COLOR_PALETTE_PRESET_TAN_BLUE_ORANGE_TECHWEAR" => "Technical wear color palette with tan, blue, and orange accents.",
    "COLOR_PALETTE_PRESET_MONOCHROMATIC_WITH_ACCENT" => "Single color family with one contrasting accent color.",
    "COLOR_PALETTE_PRESET_CUSTOM" => "Custom color palette not following preset schemes.",
    "PATTERN_THEME_TRADITIONAL_GEOMETRIC_EAST_ASIAN" => "Traditional geometric patterns inspired by East Asian design.",
    "PATTERN_THEME_CYBER_TECH" => "Futuristic technological patterns and circuit-inspired designs.",
    "PATTERN_THEME_FLORAL_STYLIZED" => "Stylized floral patterns and botanical motifs.",
    "PATTERN_THEME_MYSTICAL_SYMBOLS_RUNES" => "Magical or mystical symbols, runes, and esoteric patterns.",
    "PATTERN_THEME_CUTE_WHIMSICAL_ICONS" => "Cute, kawaii-inspired icons and whimsical design elements.",
    "PATTERN_THEME_ABSTRACT_MODERN_GEOMETRIC" => "Modern abstract geometric patterns and shapes.",
    "PATTERN_THEME_NONE" => "No specific patterns, solid colors or minimal design.",
    # Fantasy Elements
    "FANTASY_TALISMANS_TRUE" => "Magical talismans, charms, or mystical objects are present.",
    "FANTASY_TALISMANS_FALSE" => "No magical talismans or mystical objects.",
    "FANTASY_TALISMAN_TYPE_CHARM_OMAMORI" => "Japanese-style protective charms or omamori.",
    "FANTASY_TALISMAN_TYPE_PENDANT_NECKLACE" => "Magical pendants worn as necklaces.",
    "FANTASY_TALISMAN_TYPE_OFUDA_TAG" => "Paper talismans or ofuda tags with mystical writing.",
    "FANTASY_TALISMAN_TYPE_GLOWING_ORB_CRYSTAL" => "Luminous crystals or magical orbs.",
    "FANTASY_TALISMAN_TYPE_RUNESTONES" => "Carved stones with runic or magical inscriptions.",
    "FANTASY_EFFECT_GLOWING_RUNES_SYMBOLS" => "Magical effects featuring glowing runes and mystical symbols.",
    "FANTASY_EFFECT_SOFT_AURA_SHIMMER" => "Gentle magical aura with soft shimmering effects.",
    "FANTASY_EFFECT_LUMINOUS_EMBROIDERY_THREADS" => "Magical embroidery that glows or has luminous properties.",
    "FANTASY_EFFECT_FLOATING_SIGILS_PARTICLES" => "Floating magical sigils and particle effects.",
    # Cyber Elements
    "CYBER_CYBERNETICS_TRUE" => "Visible cybernetic implants or mechanical enhancements.",
    "CYBER_CYBERNETICS_FALSE" => "No visible cybernetic or mechanical body modifications.",
    "CYBERNETICS_PLACEMENT_EYE_AUGMENT_VISOR" => "Cybernetic enhancements focused on the eyes or head area.",
    "CYBERNETICS_PLACEMENT_ARM_LEG_PROSTHETIC" => "Mechanical prosthetics replacing or enhancing limbs.",
    "CYBERNETICS_PLACEMENT_INTERFACE_PORTS_SOCKETS" => "Data ports, sockets, or interface connections on the body.",
    "CYBERNETICS_PLACEMENT_SPINAL_EXOSKELETAL_ACCENTS" => "Spinal or back-mounted cybernetic enhancements.",
    "CYBER_TECH_ACCESSORIES_TRUE" => "Technological accessories and gadgets are present.",
    "CYBER_TECH_ACCESSORIES_FALSE" => "No technological accessories or cyber gadgets.",
    "CYBER_ACCESSORY_INTEGRATED_VISOR_GOGGLES" => "Head-mounted displays, visors, or cybernetic eyewear.",
    "CYBER_ACCESSORY_HOLOGRAPHIC_EARPIECE_HEADPHONES" => "Audio devices with holographic or advanced tech features.",
    "CYBER_ACCESSORY_DATA_POUCHES_CANISTERS" => "Storage containers for data, tools, or technological equipment.",
    "CYBER_ACCESSORY_UTILITY_GAUNTLETS" => "Enhanced gloves with built-in technology or tools.",
    # Traditional Elements
    "TRADITIONAL_RITUAL_ITEMS_TRUE" => "Traditional ceremonial or ritual items are present.",
    "TRADITIONAL_RITUAL_ITEMS_FALSE" => "No traditional ritual items or ceremonial objects.",
    "TRADITIONAL_RITUAL_ITEM_GOHEI_WAND" => "Traditional Shinto ceremonial wand with paper streamers.",
    "TRADITIONAL_RITUAL_ITEM_SUZU_BELL_RATTLE" => "Traditional Japanese bells or rattles used in ceremonies.",
    "TRADITIONAL_RITUAL_ITEM_CEREMONIAL_FAN" => "Decorative or ceremonial fans used in traditional practices.",
    "TRADITIONAL_RITUAL_ITEM_PRAYER_BEADS" => "Traditional prayer beads or rosary-style spiritual items.",
    "TRADITIONAL_LARGE_BOWS_TRUE" => "Large decorative bows as traditional fashion elements.",
    "TRADITIONAL_LARGE_BOWS_FALSE" => "No large decorative bows in the design.",
    "TRADITIONAL_KANZASHI_TRUE" => "Traditional Japanese hair ornaments or kanzashi accessories.",
    "TRADITIONAL_KANZASHI_FALSE" => "No traditional hair ornaments or kanzashi styling."
  }

  @moduletag :character_generation

  describe "Character Generation with AriaEngine" do
    test "builds character generation domain with all sliders" do
      domain = build_character_generation_domain()

      # Verify domain has the necessary actions and methods
      assert map_size(domain.actions) > 0
      assert map_size(domain.task_methods) > 0
    end

    test "generates character with verbose planning - level 1" do
      domain = build_character_generation_domain()

      # Generate a unique character ID for this test
      char_id = generate_character_id()

      initial_state = AriaEngine.create_state()
      |> AriaEngine.set_fact("generation_session", "active", true)
      |> AriaEngine.set_fact("character_id", "current", char_id)
      |> AriaEngine.set_fact("random_seed", "current", 12345)

      # High-level task: generate a complete character WITH CONSTRAINTS
      tasks = [{"generate_character_with_constraints", [char_id, "fantasy_cyber_preset"]}]

      case AriaEngine.plan(domain, initial_state, tasks, verbose: 0) do
        {:ok, plan} ->
          # Execute the plan
          case AriaEngine.execute_plan(domain, initial_state, plan) do
            {:ok, final_state} ->
              # Show character attributes that were set
              character_facts = final_state.data
              |> Enum.filter(fn {{category, _}, _} ->
                String.starts_with?(category, "character_")
              end)

              # Verify we have character attributes
              assert length(character_facts) > 0

              # Show the final prompt if generated
              prompt = AriaEngine.get_fact(final_state, "generated_prompt", char_id)
              if prompt do
                assert is_binary(prompt)
                assert String.length(prompt) > 0
              end

            {:error, reason} ->
              flunk("Character generation failed: #{reason}")
          end

        {:error, reason} ->
          flunk("Planning failed: #{reason}")
      end
    end

    test "generates character with verbose planning - level 2" do
      domain = build_character_generation_domain()

      # Generate a unique character ID for this test
      char_id = generate_character_id()

      initial_state = AriaEngine.create_state()
      |> AriaEngine.set_fact("generation_session", "active", true)
      |> AriaEngine.set_fact("character_id", "current", char_id)
      |> AriaEngine.set_fact("random_seed", "current", 67890)

      # More complex task: generate character with specific customizations
      tasks = [
        {"configure_character_presets", [char_id, "cyber_cat_person"]},
        {"generate_detailed_prompt", [char_id]}
      ]

      case AriaEngine.plan(domain, initial_state, tasks, verbose: 0) do
        {:ok, plan} ->
          assert is_list(plan)
          assert length(plan) > 0

        {:error, reason} ->
          flunk("Detailed planning failed: #{reason}")
      end
    end

    test "demonstrates character customization workflow" do
      domain = build_character_generation_domain()

      # Generate a unique character ID for this test
      char_id = generate_character_id()

      initial_state = AriaEngine.create_state()
      |> AriaEngine.set_fact("generation_session", "active", true)
      |> AriaEngine.set_fact("character_id", "current", char_id)

      # Group sliders by category for validation
      slider_categories = @character_sliders
      |> Enum.group_by(fn {key, _} ->
        cond do
          String.starts_with?(key, "species_") -> "Species & Body"
          String.starts_with?(key, "humanoid_") -> "Humanoid Features"
          String.starts_with?(key, "kemonomimi_") -> "Kemonomimi Features"
          String.starts_with?(key, "face_") or String.starts_with?(key, "hands_") -> "Physical Features"
          String.starts_with?(key, "primary_") or String.starts_with?(key, "rendering_") -> "Style & Theme"
          String.contains?(key, "wear") or String.contains?(key, "garment") -> "Clothing & Attire"
          String.starts_with?(key, "color_") or String.starts_with?(key, "pattern_") -> "Colors & Patterns"
          String.starts_with?(key, "fantasy_") -> "Fantasy Elements"
          String.starts_with?(key, "cyber_") -> "Cyber Elements"
          String.starts_with?(key, "traditional_") -> "Traditional Elements"
          true -> "Other"
        end
      end)

      # Verify we have slider categories
      assert map_size(slider_categories) > 0

      # Test customization task
      customization_tasks = [
        {"customize_species", [char_id, "SPECIES_BASE_SEMI_HUMANOID"]},
        {"customize_archetype", [char_id, "HUMANOID_ARCHETYPE_CAT_PERSON"]},
        {"customize_theme", [char_id, "PRIMARY_THEME_PASTEL_CYBER"]},
        {"finalize_character_prompt", [char_id]}
      ]

      case AriaEngine.plan(domain, initial_state, customization_tasks, verbose: 0) do
        {:ok, plan} ->
          assert length(plan) > 0

          case AriaEngine.execute_plan(domain, initial_state, plan) do
            {:ok, final_state} ->
              # Show configured attributes
              configured_attrs = final_state.data
              |> Enum.filter(fn {{category, _}, _} ->
                String.starts_with?(category, "character_")
              end)
              |> Enum.sort()

              # Verify we have configured attributes
              assert length(configured_attrs) > 0

            {:error, reason} ->
              flunk("Customization execution failed: #{reason}")
          end

        {:error, reason} ->
          flunk("Customization planning failed: #{reason}")
      end
    end

    # Unit Tests for Prompt Generation (demonstrating text-only character generation)

    test "weighted random choice works correctly" do
      options = ["A", "B", "C"]
      weights = [0.5, 0.3, 0.2]

      # Test multiple times to verify distribution
      results = for _ <- 1..100 do
        weighted_random_choice(options, weights)
      end

      # All results should be valid options
      assert Enum.all?(results, &(&1 in options))

      # Test edge cases
      assert weighted_random_choice([], []) == nil
      assert weighted_random_choice(["A"], [1.0]) == "A"
      assert weighted_random_choice(["A", "B"], [0.5]) == nil  # mismatched lengths
    end

    test "randomize character sliders generates valid attributes" do
      attributes = randomize_character_sliders(12345)

      # Check that all core sliders are present
      core_sliders = ["species", "emotion", "style_kei", "color_palette",
                     "key_motifs", "layering_style", "detail_level",
                     "age", "avatar_gender_appearance"]

      for slider_name <- core_sliders do
        assert Map.has_key?(attributes, slider_name), "Missing slider: #{slider_name}"

        slider_info = @character_sliders[slider_name]
        value = attributes[slider_name]

        case slider_info.type do
          "categorical" ->
            assert value in slider_info.options, "Invalid value #{value} for #{slider_name}"
          "numeric" ->
            assert is_integer(value), "#{slider_name} should be numeric"
            assert value >= slider_info.min and value <= slider_info.max,
                   "#{slider_name} value #{value} out of range"
        end
      end
    end

    test "construct character prompt builds proper descriptive text" do
      # Test with known attributes
      attributes = %{
        "species" => "SPECIES_SEMI_HUMANOID",
        "emotion" => "EMOTION_HAPPY",
        "style_kei" => "STYLE_KEI_ANIME",
        "color_palette" => "COLOR_PALETTE_ANIME_INSPIRED",
        "key_motifs" => "KEY_MOTIFS_GLOWING_ACCENTS",
        "layering_style" => "LAYERING_STYLE_MULTI_LAYERED_STREETWEAR",
        "detail_level" => 7,
        "age" => "AGE_ADULT",
        "avatar_gender_appearance" => "AVATAR_GENDER_APPEARANCE_FEMININE"
      }

      prompt = construct_character_prompt(attributes)

      # Verify prompt contains expected elements
      assert String.contains?(prompt, "mature individual")  # This is how "Adult" appears in descriptions
      assert String.contains?(prompt, "female individuals")
      assert String.contains?(prompt, "joyful")
      assert String.contains?(prompt, "semi-humanoid")
      assert String.contains?(prompt, "anime")
      assert String.contains?(prompt, "anime-inspired") || String.contains?(prompt, "Color schemes commonly found in anime")
      assert String.contains?(prompt, "glowing") || String.contains?(prompt, "Luminous details")
      assert String.contains?(prompt, "multi-layered") || String.contains?(prompt, "streetwear")
      assert String.contains?(prompt, "Detail level 7")
      assert String.contains?(prompt, "Full body shot")
      assert String.contains?(prompt, "A-Pose")
      assert String.contains?(prompt, "3D modeling concept art")
    end

    test "workflow generate prompt only produces complete results" do
      {attributes, prompt} = workflow_generate_prompt_only(42)

      # Verify attributes are populated
      assert is_map(attributes)
      assert map_size(attributes) >= 9  # At least the core 9 sliders

      # Verify prompt is a non-empty string
      assert is_binary(prompt)
      assert String.length(prompt) > 50
      assert String.contains?(prompt, "Full body shot")
    end

    test "workflow generate prompt batch creates multiple unique prompts" do
      num_prompts = 5
      batch_results = workflow_generate_prompt_batch(num_prompts)

      assert length(batch_results) == num_prompts

      # Check each result has required fields
      for result <- batch_results do
        assert Map.has_key?(result, :prompt_id)
        assert Map.has_key?(result, :seed)
        assert Map.has_key?(result, :iteration)
        assert Map.has_key?(result, :attributes)
        assert Map.has_key?(result, :prompt)

        assert is_binary(result.prompt)
        assert String.length(result.prompt) > 50
        assert is_map(result.attributes)
        assert is_integer(result.seed)
      end

      # Verify prompts are different (high probability with randomization)
      prompts = Enum.map(batch_results, & &1.prompt)
      unique_prompts = Enum.uniq(prompts)
      assert length(unique_prompts) >= 3, "Expected more variation in generated prompts"
    end

    test "run prompt only pipeline orchestrates batch generation" do
      results = run_prompt_only_pipeline(3)

      assert length(results) == 3
      assert Enum.all?(results, &Map.has_key?(&1, :prompt))
      assert Enum.all?(results, &Map.has_key?(&1, :attributes))
    end

    test "deterministic generation with seeds" do
      # Same seed should produce same results
      {attrs1, prompt1} = workflow_generate_prompt_only(999)
      {attrs2, prompt2} = workflow_generate_prompt_only(999)

      assert attrs1 == attrs2
      assert prompt1 == prompt2

      # Different seeds should produce different results (high probability)
      {attrs3, _prompt3} = workflow_generate_prompt_only(1000)
      assert attrs1 != attrs3  # Very likely to be different
    end

    test "all option descriptions are available" do
      # Test that we have descriptions for all possible slider values
      for {slider_name, slider_info} <- @character_sliders do
        if slider_info.type == "categorical" do
          for option <- slider_info.options do
            description = Map.get(@option_descriptions, option)
            assert description != nil, "Missing description for #{option} in #{slider_name}"
            assert is_binary(description), "Description should be a string"
            assert String.length(description) > 0, "Description should not be empty"
          end
        end
      end
    end

    test "prompt generation handles missing attributes gracefully" do
      # Test with minimal attributes
      minimal_attrs = %{
        "species" => "SPECIES_HUMANOID",
        "detail_level" => 5
      }

      prompt = construct_character_prompt(minimal_attrs)

      # Should still generate a valid prompt using defaults
      assert is_binary(prompt)
      assert String.length(prompt) > 30
      assert String.contains?(prompt, "Detail level 5")
    end

    test "end-to-end text prompt generation workflow" do
      {attributes, prompt} = workflow_generate_prompt_only()
      for {key, value} <- attributes do
        description = if key == "detail_level" do
          to_string(value)
        else
          Map.get(@option_descriptions, value, value)
        end
      end
      batch_results = workflow_generate_prompt_batch(3)
      # Verify all results are valid
      assert length(batch_results) == 3
      assert Enum.all?(batch_results, fn result ->
        String.contains?(result.prompt, "Full body shot") and
        String.contains?(result.prompt, "3D modeling concept art")
      end)
    end
  end

  # Build the character generation domain with actions and methods
  defp build_character_generation_domain do
    domain = AriaEngine.create_domain()

    # Add basic actions for character generation
    domain = domain
    |> AriaEngine.add_action(:set_character_attribute,
        fn state, [char_id, attribute, value] ->
          new_state = AriaEngine.set_fact(state, "character_#{attribute}", char_id, value)
          {:ok, new_state}
        end)

    |> AriaEngine.add_action(:randomize_attribute,
        fn state, [char_id, attribute] ->
          slider_config = @character_sliders[attribute]
          if slider_config do
            options = Map.get(slider_config, :options, [])
            random_value = if length(options) > 0, do: Enum.random(options), else: Map.get(slider_config, :default)
            new_state = AriaEngine.set_fact(state, "character_#{attribute}", char_id, random_value)
            {:ok, new_state}
          else
            {:error, "Unknown attribute: #{attribute}"}
          end
        end)

    |> AriaEngine.add_action(:generate_text_prompt,
        fn state, [char_id] ->
          # Collect all character attributes
          character_attrs = state.data
          |> Enum.filter(fn {{category, id}, _} ->
            String.starts_with?(category, "character_") and id == char_id
          end)
          |> Enum.map(fn {{category, _id}, value} ->
            attribute = String.replace(category, "character_", "")
            {attribute, value}
          end)
          |> Enum.into(%{})

          # Generate a descriptive prompt
          prompt = build_character_prompt(character_attrs)
          new_state = AriaEngine.set_fact(state, "generated_prompt", char_id, prompt)
          {:ok, new_state}
        end)
    |> AriaEngine.add_action(:validate_constraints,
        fn state, [char_id] ->
          # Get all character attributes
          attributes = get_character_attributes(state, char_id)
          violations = check_constraint_violations(attributes)

          if length(violations) > 0 do
            {:error, "Constraint violations: #{Enum.join(violations, ", ")}"}
          else
            {:ok, state}
          end
        end)

    |> AriaEngine.add_action(:resolve_dependency,
        fn state, [char_id, dependent_attr, dependency_attr, required_value] ->
          current_value = AriaEngine.get_fact(state, "character_#{dependency_attr}", char_id)
          if current_value == required_value do
            {:ok, state}
          else
            # Set the dependency to the required value
            new_state = AriaEngine.set_fact(state, "character_#{dependency_attr}", char_id, required_value)
            {:ok, new_state}
          end
        end)

    |> AriaEngine.add_action(:auto_correct_conflicts,
        fn state, [char_id] ->
          attributes = get_character_attributes(state, char_id)
          corrected_attributes = resolve_conflicts(attributes)

          # Apply corrections
          new_state = Enum.reduce(corrected_attributes, state, fn {attr, value}, acc_state ->
            AriaEngine.set_fact(acc_state, "character_#{attr}", char_id, value)
          end)

          {:ok, new_state}
        end)

    # Add hierarchical task methods with constraint checking
    domain = domain
    |> AriaEngine.add_task_method("generate_character_with_constraints",
        fn _state, [char_id, preset] ->
          [
            {"configure_character_presets", [char_id, preset]},
            {"validate_and_resolve_constraints", [char_id]},
            {"randomize_remaining_attributes_safely", [char_id]},
            {"final_constraint_validation", [char_id]},
            {"generate_detailed_prompt", [char_id]},
          ]
        end)

    # Fallback method for generate_character_with_constraints if constraints fail
    |> AriaEngine.add_task_method("generate_character_with_constraints",
        fn state, [char_id, preset] ->
          # This method will be tried if the first one fails due to constraints
          [
            {"configure_simple_preset", [char_id]},
            {"validate_and_resolve_constraints", [char_id]},
            {"randomize_remaining_attributes_safely", [char_id]},
            {"generate_detailed_prompt", [char_id]},
          ]
        end)

    |> AriaEngine.add_task_method("generate_character",
        fn _state, [char_id, preset] ->
          [
            {"configure_character_presets", [char_id, preset]},
            {"randomize_remaining_attributes", [char_id]},
            {"generate_detailed_prompt", [char_id]},
          ]
        end)

    |> AriaEngine.add_task_method("configure_character_presets",
        fn _state, [char_id, preset] ->
          case preset do
            "fantasy_cyber_preset" ->
              [
                {:set_character_attribute, [char_id, "species_base_type", "SPECIES_BASE_HUMANOID"]},
                {:set_character_attribute, [char_id, "primary_theme", "PRIMARY_THEME_PASTEL_CYBER"]},
                {:set_character_attribute, [char_id, "cyber_tech_accessories_presence", "CYBER_TECH_ACCESSORIES_TRUE"]},
                {:set_character_attribute, [char_id, "fantasy_magical_talismans_presence", "FANTASY_TALISMANS_TRUE"]},
              ]
            "cyber_cat_person" ->
              [
                {:set_character_attribute, [char_id, "species_base_type", "SPECIES_BASE_SEMI_HUMANOID"]},
                {:set_character_attribute, [char_id, "humanoid_archetype", "HUMANOID_ARCHETYPE_CAT_PERSON"]},
                {:set_character_attribute, [char_id, "kemonomimi_animal_ears_presence", "KEMONOMIMI_EARS_TRUE"]},
                {:set_character_attribute, [char_id, "kemonomimi_animal_tail_presence", "KEMONOMIMI_TAIL_TRUE"]},
                {:set_character_attribute, [char_id, "primary_theme", "PRIMARY_THEME_CYBERPREP_TECHWEAR"]},
              ]
            _ ->
              [
                {:set_character_attribute, [char_id, "species_base_type", "SPECIES_BASE_HUMANOID"]},
              ]
          end
        end)

    |> AriaEngine.add_task_method("validate_and_resolve_constraints",
        fn state, [char_id] ->
          attributes = get_character_attributes(state, char_id)
          violations = check_constraint_violations(attributes)

          if length(violations) > 0 do
            # Try to auto-resolve conflicts first
            [
              {:auto_correct_conflicts, [char_id]},
              {:validate_constraints, [char_id]}
            ]
          end
        end)

    # Alternative method for validate_and_resolve_constraints that fails if conflicts can't be resolved
    |> AriaEngine.add_task_method("validate_and_resolve_constraints",
        fn state, [char_id] ->
          # This method will be tried if auto-correction fails
          # It forces a complete reset of problematic attributes
          [
            {"reset_conflicting_attributes", [char_id]},
            {:validate_constraints, [char_id]}
          ]
        end)

    |> AriaEngine.add_task_method("randomize_remaining_attributes_safely",
        fn state, [char_id] ->
          # Find attributes that haven't been set yet
          set_attributes = state.data
          |> Enum.filter(fn {{category, id}, _} ->
            String.starts_with?(category, "character_") and id == char_id
          end)
          |> Enum.map(fn {{category, _id}, _value} ->
            String.replace(category, "character_", "")
          end)
          |> MapSet.new()

          available_attributes = @character_sliders
          |> Map.keys()
          |> MapSet.new()

          unset_attributes = MapSet.difference(available_attributes, set_attributes)
          |> Enum.take(8)  # Randomize more attributes but safely

          # Build randomization actions with constraint checks
          randomize_actions = Enum.flat_map(unset_attributes, fn attr ->
            [
              {:randomize_attribute, [char_id, attr]},
            ]
          end)
        end)

    # Alternative method for randomize_remaining_attributes_safely if constraint checking fails
    |> AriaEngine.add_task_method("randomize_remaining_attributes_safely",
        fn state, [char_id] ->
          # Fallback: only randomize safe attributes that rarely cause conflicts
          safe_attributes = ["detail_level", "age", "avatar_gender_appearance", "emotion"]

          set_attributes = state.data
          |> Enum.filter(fn {{category, id}, _} ->
            String.starts_with?(category, "character_") and id == char_id
          end)
          |> Enum.map(fn {{category, _id}, _value} ->
            String.replace(category, "character_", "")
          end)
          |> MapSet.new()

          unset_safe_attributes = safe_attributes
          |> Enum.reject(fn attr -> MapSet.member?(set_attributes, attr) end)

          randomize_actions = Enum.map(unset_safe_attributes, fn attr ->
            {:randomize_attribute, [char_id, attr]}
          end)
        end)

    |> AriaEngine.add_task_method("final_constraint_validation",
        fn state, [char_id] ->
          # Final validation that must pass - if it fails, the whole generation fails
          [
            {:validate_constraints, [char_id]},
          ]
        end)

    |> AriaEngine.add_task_method("configure_simple_preset",
        fn _state, [char_id] ->
          # A very simple preset that's unlikely to cause conflicts
          [
            {:set_character_attribute, [char_id, "species", "SPECIES_HUMANOID"]},
            {:set_character_attribute, [char_id, "style_kei", "STYLE_KEI_ANIME"]},
            {:set_character_attribute, [char_id, "emotion", "EMOTION_NEUTRAL"]},
          ]
        end)

    |> AriaEngine.add_task_method("reset_conflicting_attributes",
        fn state, [char_id] ->
          # Reset attributes that commonly cause conflicts
          conflicting_attrs = [
            "kemonomimi_animal_ears_presence",
            "kemonomimi_animal_tail_presence",
            "cyber_visible_cybernetics_presence",
            "fantasy_magical_talismans_presence"
          ]

          reset_actions = Enum.map(conflicting_attrs, fn attr ->
            {:set_character_attribute, [char_id, attr, nil]}
          end)
        end)

    |> AriaEngine.add_task_method("randomize_remaining_attributes",
        fn state, [char_id] ->
          # Find attributes that haven't been set yet
          set_attributes = state.data
          |> Enum.filter(fn {{category, id}, _} ->
            String.starts_with?(category, "character_") and id == char_id
          end)
          |> Enum.map(fn {{category, _id}, _value} ->
            String.replace(category, "character_", "")
          end)
          |> MapSet.new()

          available_attributes = @character_sliders
          |> Map.keys()
          |> MapSet.new()

          unset_attributes = MapSet.difference(available_attributes, set_attributes)
          |> Enum.take(5)  # Limit to 5 for demo

          randomize_actions = Enum.map(unset_attributes, fn attr ->
            {:randomize_attribute, [char_id, attr]}
          end)
        end)

    |> AriaEngine.add_task_method("generate_detailed_prompt",
        fn _state, [char_id] ->
          [
            {:generate_text_prompt, [char_id]},
          ]
        end)

    |> AriaEngine.add_task_method("customize_species",
        fn _state, [char_id, species_type] ->
          [
            {:set_character_attribute, [char_id, "species_base_type", species_type]},
          ]
        end)

    |> AriaEngine.add_task_method("customize_archetype",
        fn _state, [char_id, archetype] ->
          [
            {:set_character_attribute, [char_id, "humanoid_archetype", archetype]},
          ]
        end)

    |> AriaEngine.add_task_method("customize_theme",
        fn _state, [char_id, theme] ->
          [
            {:set_character_attribute, [char_id, "primary_theme", theme]},
          ]
        end)

    |> AriaEngine.add_task_method("finalize_character_prompt",
        fn _state, [char_id] ->
          [
            {"generate_detailed_prompt", [char_id]},
          ]
        end)

    |> AriaEngine.add_task_method("generate_character_with_constraints",
        fn state, [char_id, preset_name] ->
          [
            {"configure_character_presets", [char_id, preset_name]},
            {"validate_and_resolve_constraints", [char_id]},
            {"generate_detailed_prompt", [char_id]}
          ]
        end)

    |> AriaEngine.add_task_method("validate_and_resolve_constraints",
        fn state, [char_id] ->
          [
            {:validate_constraints, [char_id]},
            {"resolve_feature_dependencies", [char_id]},
            {"resolve_thematic_conflicts", [char_id]},
            {:auto_correct_conflicts, [char_id]},
            {:validate_constraints, [char_id]}  # Final validation
          ]
        end)

    |> AriaEngine.add_task_method("resolve_feature_dependencies",
        fn state, [char_id] ->
          # Handle kemonomimi feature dependencies
          actions = []

          # If we have animal ears/tail but human archetype, fix archetype
          ears = AriaEngine.get_fact(state, "character_kemonomimi_animal_ears_presence", char_id)
          tail = AriaEngine.get_fact(state, "character_kemonomimi_animal_tail_presence", char_id)
          archetype = AriaEngine.get_fact(state, "character_humanoid_archetype", char_id)

          actions = if (ears == "KEMONOMIMI_EARS_TRUE" or tail == "KEMONOMIMI_TAIL_TRUE") and
                       archetype == "HUMANOID_ARCHETYPE_HUMAN_FEATURED" do
            [
              {:set_character_attribute, [char_id, "humanoid_archetype", "HUMANOID_ARCHETYPE_CAT_PERSON"]},
            ]
          else
            actions
          end

          # Handle presence flags vs specific types
          fantasy_presence = AriaEngine.get_fact(state, "character_fantasy_magical_talismans_presence", char_id)
          actions = if fantasy_presence == "FANTASY_TALISMANS_FALSE" do
            [
              {:set_character_attribute, [char_id, "fantasy_magical_talismans_type", nil]},
            ]
          else
            actions
          end

          cyber_presence = AriaEngine.get_fact(state, "character_cyber_tech_accessories_presence", char_id)
          actions = if cyber_presence == "CYBER_TECH_ACCESSORIES_FALSE" do
            [
              {:set_character_attribute, [char_id, "cyber_tech_accessories_type", nil]},
            ]
          else
            actions
          end

          Enum.reverse(actions)
        end)

    |> AriaEngine.add_task_method("resolve_thematic_conflicts",
        fn state, [char_id] ->
          # Handle style/theme conflicts
          style_kei = AriaEngine.get_fact(state, "character_style_kei", char_id)
          primary_theme = AriaEngine.get_fact(state, "character_primary_theme", char_id)
          species = AriaEngine.get_fact(state, "character_species", char_id)

          actions = []

          # Fix robotic + furry conflicts
          actions = if style_kei == "STYLE_KEI_ROBOTIC_CYBORG" and species == "SPECIES_ANIMAL" do
            [
              {:set_character_attribute, [char_id, "species", "SPECIES_HUMANOID_ROBOT_OR_CYBORG"]},
            ]
          else
            actions
          end

          # Fix traditional theme + cyber elements conflicts
          actions = if primary_theme == "PRIMARY_THEME_TRADITIONAL_SHRINE_MAIDEN" do
            cyber_presence = AriaEngine.get_fact(state, "character_cyber_visible_cybernetics_presence", char_id)
            if cyber_presence == "CYBER_CYBERNETICS_TRUE" do
              [
                {:set_character_attribute, [char_id, "cyber_visible_cybernetics_presence", "CYBER_CYBERNETICS_FALSE"]},
              ]
            else
              actions
            end
          else
            actions
          end

          Enum.reverse(actions)
        end)

    domain
  end

  # Build a character description prompt from attributes
  defp build_character_prompt(attributes) do
    prompt_parts = []

    # Species and archetype
    prompt_parts = if attributes["species_base_type"] do
      species_desc = case attributes["species_base_type"] do
        "SPECIES_BASE_HUMANOID" -> "humanoid character"
        "SPECIES_BASE_SEMI_HUMANOID" -> "semi-humanoid character"
        "SPECIES_BASE_ANIMAL" -> "animal character"
        "SPECIES_BASE_ROBOTIC_CYBORG" -> "robotic cyborg character"
        _ -> "character"
      end
      [species_desc | prompt_parts]
    else
      prompt_parts
    end

    # Archetype details
    prompt_parts = if attributes["humanoid_archetype"] do
      archetype_desc = case attributes["humanoid_archetype"] do
        "HUMANOID_ARCHETYPE_FOX_PERSON" -> "with fox-like features"
        "HUMANOID_ARCHETYPE_CAT_PERSON" -> "with cat-like features"
        "HUMANOID_ARCHETYPE_OTHER_KEMONOMIMI" -> "with animal-like features"
        _ -> ""
      end
      if archetype_desc != "", do: [archetype_desc | prompt_parts], else: prompt_parts
    else
      prompt_parts
    end

    # Physical features
    if attributes["kemonomimi_animal_ears_presence"] == "KEMONOMIMI_EARS_TRUE" do
      prompt_parts = ["with animal ears" | prompt_parts]
    end

    if attributes["kemonomimi_animal_tail_presence"] == "KEMONOMIMI_TAIL_TRUE" do
      tail_style = case attributes["kemonomimi_animal_tail_style"] do
        "KEMONOMIMI_TAIL_STYLE_FLUFFY" -> "fluffy tail"
        "KEMONOMIMI_TAIL_STYLE_SLEEK" -> "sleek tail"
        "KEMONOMIMI_TAIL_STYLE_LONG_FLOWING" -> "long flowing tail"
        _ -> "tail"
      end
      prompt_parts = ["with #{tail_style}" | prompt_parts]
    end

    # Theme and style
    prompt_parts = if attributes["primary_theme"] do
      theme_desc = case attributes["primary_theme"] do
        "PRIMARY_THEME_FANTASY_EAST_ASIAN" -> "in fantasy East Asian style"
        "PRIMARY_THEME_CYBERPREP_TECHWEAR" -> "in cyberprep techwear style"
        "PRIMARY_THEME_PASTEL_CYBER" -> "in pastel cyber style"
        "PRIMARY_THEME_TRADITIONAL_SHRINE_MAIDEN" -> "in traditional shrine maiden style"
        "PRIMARY_THEME_CASUAL_TECH_STREETWEAR" -> "in casual tech streetwear style"
        "PRIMARY_THEME_MORI_KEI_NATURALIST" -> "in mori kei naturalist style"
        _ -> ""
      end
      if theme_desc != "", do: [theme_desc | prompt_parts], else: prompt_parts
    else
      prompt_parts
    end

    # Rendering style
    prompt_parts = if attributes["rendering_style"] do
      render_desc = case attributes["rendering_style"] do
        "RENDERING_STYLE_TOON_SHADED" -> "toon shaded"
        "RENDERING_STYLE_PAINTERLY_STYLIZED_3D" -> "painterly stylized 3D"
        "RENDERING_STYLE_PIXEL_ART_TEXTURE_3D" -> "pixel art textured 3D"
        "RENDERING_STYLE_VOXEL_ART" -> "voxel art"
        _ -> ""
      end
      if render_desc != "", do: [render_desc | prompt_parts], else: prompt_parts
    else
      prompt_parts
    end

    # Accessories and elements
    if attributes["cyber_tech_accessories_presence"] == "CYBER_TECH_ACCESSORIES_TRUE" do
      prompt_parts = ["with cyber tech accessories" | prompt_parts]
    end

    if attributes["fantasy_magical_talismans_presence"] == "FANTASY_TALISMANS_TRUE" do
      prompt_parts = ["carrying magical talismans" | prompt_parts]
    end

    # Build final prompt
    if length(prompt_parts) > 0 do
      prompt_parts
      |> Enum.reverse()
      |> Enum.join(", ")
      |> String.capitalize()
    else
      "A character"
    end
  end

  # Helper function for weighted random choice (ported from Python op_custom_weighted_random_choice)
  defp weighted_random_choice(options, weights) do
    if length(options) != length(weights) or Enum.empty?(options) do
      nil
    else
      # Create cumulative weights
      total = Enum.sum(weights)
      random_val = :rand.uniform() * total

      options
      |> Enum.zip(weights)
      |> Enum.reduce_while({0, nil}, fn {option, weight}, {acc, _} ->
        new_acc = acc + weight
        if random_val <= new_acc do
          {:halt, {new_acc, option}}
        else
          {:cont, {new_acc, nil}}
        end
      end)
      |> elem(1)
    end
  end

  # Randomize character sliders (ported from Python op_complex_randomize_sliders)
  defp randomize_character_sliders(seed \\ nil) do
    if seed, do: :rand.seed(:exsplus, {seed, seed + 1, seed + 2})

    Enum.reduce(@character_sliders, %{}, fn {slider_name, slider_info}, acc ->
      chosen_value = case Map.get(slider_info, :type, "categorical") do
        "categorical" ->
          options = Map.get(slider_info, :options, [])
          weights = Map.get(@slider_weights, slider_name)

          if weights && length(weights) == length(options) && length(options) > 0 do
            weighted_random_choice(options, weights)
          else
            case options do
              [] -> Map.get(slider_info, :default)
              _ -> Enum.random(options)
            end
          end

        "numeric" ->
          min_val = Map.get(slider_info, :min, 1)
          max_val = Map.get(slider_info, :max, 10)
          range = max_val - min_val
          min_val + (:rand.uniform() * range) |> round()

        _ ->
          Map.get(slider_info, :default)
      end

      chosen_value = chosen_value || Map.get(slider_info, :default)
      Map.put(acc, slider_name, chosen_value)
    end)
  end

  # Construct prompt from character attributes (ported from Python op_complex_construct_prompt)
  defp construct_character_prompt(attributes) do
    required_keys = [
      "species", "emotion", "style_kei", "color_palette",
      "key_motifs", "layering_style", "detail_level",
      "age", "avatar_gender_appearance"
    ]

    # Build descriptions map
    descriptions = Enum.reduce(required_keys, %{}, fn key, acc ->
      value = Map.get(attributes, key) || Map.get(@character_sliders[key], :default)

      description = if key == "detail_level" do
        to_string(value)
      else
        Map.get(@option_descriptions, value, value)
      end

      Map.put(acc, key, description)
    end)

    # Build prompt using same template as Python version
    "#{descriptions["age"]} #{descriptions["avatar_gender_appearance"]} #{descriptions["emotion"]} #{descriptions["species"]} " <>
    "in #{descriptions["style_kei"]} style. Color palette: #{descriptions["color_palette"]}. " <>
    "Key motifs: #{descriptions["key_motifs"]}. Layering: #{descriptions["layering_style"]}. " <>
    "Detail level #{descriptions["detail_level"]}. " <>
    "Full body shot, A-Pose (arms slightly down, not T-Pose), clear view of hands and feet. 3D modeling concept art."
  end

  # Single prompt generation workflow (ported from Python m_workflow_generate_prompt_only)
  defp workflow_generate_prompt_only(seed \\ nil) do
    attributes = randomize_character_sliders(seed)
    prompt = construct_character_prompt(attributes)
    {attributes, prompt}
  end

  # Batch prompt generation workflow (ported from Python m_workflow_generate_prompt_batch)
  defp workflow_generate_prompt_batch(num_prompts) do
    timestamp = DateTime.utc_now() |> DateTime.to_iso8601()

    Enum.map(0..(num_prompts - 1), fn i ->
      seed = :rand.uniform(1_000_000)
      prompt_id = "#{timestamp}_#{i}"
      {attributes, prompt} = workflow_generate_prompt_only(seed)

      %{
        prompt_id: prompt_id,
        seed: seed,
        iteration: i,
        attributes: attributes,
        prompt: prompt
      }
    end)
  end

  # Run prompt-only pipeline (ported from Python m_run_prompt_only_pipeline)
  defp run_prompt_only_pipeline(num_prompts) do
    workflow_generate_prompt_batch(num_prompts)
  end

  # Helper function to get all character attributes from state
  defp get_character_attributes(state, char_id) do
    state.data
    |> Enum.filter(fn {{category, id}, _} ->
      String.starts_with?(category, "character_") and id == char_id
    end)
    |> Enum.into(%{}, fn {{category, _id}, value} ->
      attr_name = String.replace(category, "character_", "")
      {attr_name, value}
    end)
  end

  # Check for constraint violations
  defp check_constraint_violations(attributes) do
    violations = []

    # Check kemonomimi feature consistency
    violations = check_kemonomimi_consistency(attributes, violations)

    # Check presence/type consistency
    violations = check_presence_type_consistency(attributes, violations)

    # Check thematic conflicts
    violations = check_thematic_conflicts(attributes, violations)

    # Check species/style consistency
    violations = check_species_style_consistency(attributes, violations)

    violations
  end

  defp check_kemonomimi_consistency(attributes, violations) do
    ears = Map.get(attributes, "kemonomimi_animal_ears_presence")
    tail = Map.get(attributes, "kemonomimi_animal_tail_presence")
    archetype = Map.get(attributes, "humanoid_archetype")
    tail_style = Map.get(attributes, "kemonomimi_animal_tail_style")

    violations = if (ears == "KEMONOMIMI_EARS_TRUE" or tail == "KEMONOMIMI_TAIL_TRUE") and
                    archetype == "HUMANOID_ARCHETYPE_HUMAN_FEATURED" do
      ["Animal features with human archetype" | violations]
    else
      violations
    end

    violations = if tail == "KEMONOMIMI_TAIL_FALSE" and tail_style != nil do
      ["Tail style set but no tail present" | violations]
    else
      violations
    end

    violations
  end

  defp check_presence_type_consistency(attributes, violations) do
    violations = check_feature_presence_type(attributes, violations,
      "fantasy_magical_talismans_presence", "FANTASY_TALISMANS_FALSE",
      "fantasy_magical_talismans_type", "Fantasy talisman type set but no talismans present")

    violations = check_feature_presence_type(attributes, violations,
      "cyber_tech_accessories_presence", "CYBER_TECH_ACCESSORIES_FALSE",
      "cyber_tech_accessories_type", "Cyber accessory type set but no accessories present")

    violations = check_feature_presence_type(attributes, violations,
      "cyber_visible_cybernetics_presence", "CYBER_CYBERNETICS_FALSE",
      "cyber_visible_cybernetics_placement", "Cybernetics placement set but no cybernetics present")

    violations
  end

  defp check_feature_presence_type(attributes, violations, presence_key, false_value, type_key, error_message) do
    presence = Map.get(attributes, presence_key)
    type_value = Map.get(attributes, type_key)

    if presence == false_value and type_value != nil do
      [error_message | violations]
    else
      violations
    end
  end

  defp check_thematic_conflicts(attributes, violations) do
    style_kei = Map.get(attributes, "style_kei")
    primary_theme = Map.get(attributes, "primary_theme")
    cyber_presence = Map.get(attributes, "cyber_visible_cybernetics_presence")
    fantasy_presence = Map.get(attributes, "fantasy_magical_talismans_presence")

    violations = if primary_theme == "PRIMARY_THEME_TRADITIONAL_SHRINE_MAIDEN" and
                    cyber_presence == "CYBER_CYBERNETICS_TRUE" do
      ["Traditional shrine maiden theme conflicts with cybernetics" | violations]
    else
      violations
    end

    violations = if style_kei == "STYLE_KEI_ROBOTIC_CYBORG" and
                    fantasy_presence == "FANTASY_TALISMANS_TRUE" do
      ["Robotic style conflicts with fantasy talismans" | violations]
    else
      violations
    end

    violations
  end

  defp check_species_style_consistency(attributes, violations) do
    species = Map.get(attributes, "species")
    style_kei = Map.get(attributes, "style_kei")

    violations = if species == "SPECIES_ANIMAL" and style_kei == "STYLE_KEI_ROBOTIC_CYBORG" do
      ["Animal species conflicts with robotic style" | violations]
    else
      violations
    end

    violations = if species == "SPECIES_HUMANOID_ROBOT_OR_CYBORG" and style_kei == "STYLE_KEI_FURRY" do
      ["Robot/cyborg species conflicts with furry style" | violations]
    else
      violations
    end

    violations
  end

  # Resolve conflicts automatically
  defp resolve_conflicts(attributes) do
    corrected = Map.new(attributes)

    # Apply resolution rules
    corrected = resolve_kemonomimi_conflicts(corrected)
    corrected = resolve_presence_type_conflicts(corrected)
    corrected = resolve_thematic_conflicts(corrected)
    corrected = resolve_species_style_conflicts(corrected)

    corrected
  end

  defp resolve_kemonomimi_conflicts(attributes) do
    ears = Map.get(attributes, "kemonomimi_animal_ears_presence")
    tail = Map.get(attributes, "kemonomimi_animal_tail_presence")
    archetype = Map.get(attributes, "humanoid_archetype")

    # If we have animal features but human archetype, change to cat person
    if (ears == "KEMONOMIMI_EARS_TRUE" or tail == "KEMONOMIMI_TAIL_TRUE") and
       archetype == "HUMANOID_ARCHETYPE_HUMAN_FEATURED" do
      Map.put(attributes, "humanoid_archetype", "HUMANOID_ARCHETYPE_CAT_PERSON")
    else
      attributes
    end
  end

  defp resolve_presence_type_conflicts(attributes) do
    attributes
    |> clear_type_if_not_present("fantasy_magical_talismans_presence", "FANTASY_TALISMANS_FALSE", "fantasy_magical_talismans_type")
    |> clear_type_if_not_present("cyber_tech_accessories_presence", "CYBER_TECH_ACCESSORIES_FALSE", "cyber_tech_accessories_type")
    |> clear_type_if_not_present("cyber_visible_cybernetics_presence", "CYBER_CYBERNETICS_FALSE", "cyber_visible_cybernetics_placement")
  end

  defp clear_type_if_not_present(attributes, presence_key, false_value, type_key) do
    if Map.get(attributes, presence_key) == false_value do
      Map.put(attributes, type_key, nil)
    else
      attributes
    end
  end

  defp resolve_thematic_conflicts(attributes) do
    primary_theme = Map.get(attributes, "primary_theme")

    # If traditional theme, disable conflicting modern elements
    if primary_theme == "PRIMARY_THEME_TRADITIONAL_SHRINE_MAIDEN" do
      attributes
      |> Map.put("cyber_visible_cybernetics_presence", "CYBER_CYBERNETICS_FALSE")
      |> Map.put("cyber_tech_accessories_presence", "CYBER_TECH_ACCESSORIES_FALSE")
    else
      attributes
    end
  end

  defp resolve_species_style_conflicts(attributes) do
    species = Map.get(attributes, "species")
    style_kei = Map.get(attributes, "style_kei")

    cond do
      species == "SPECIES_ANIMAL" and style_kei == "STYLE_KEI_ROBOTIC_CYBORG" ->
        # Prioritize style, change species to match
        Map.put(attributes, "species", "SPECIES_HUMANOID_ROBOT_OR_CYBORG")

      species == "SPECIES_HUMANOID_ROBOT_OR_CYBORG" and style_kei == "STYLE_KEI_FURRY" ->
        # Prioritize species, change style to match
        Map.put(attributes, "style_kei", "STYLE_KEI_ROBOTIC_CYBORG")

      true ->
        attributes
    end
  end
end
