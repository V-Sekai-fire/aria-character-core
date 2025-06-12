# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.CharacterGenerator.Config do
  @moduledoc """
  Character generator configuration including sliders, weights, and option descriptions.
  
  This module contains all the configuration data needed for character generation,
  including attribute definitions, probability weights, and human-readable descriptions.
  """

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
    "face_style" => %{
      type: "categorical",
      options: [
        "FACE_STYLE_ANIME_SOFT",
        "FACE_STYLE_ANIME_SHARP_MATURE",
        "FACE_STYLE_STYLIZED_NON_ANIME"
      ],
      default: "FACE_STYLE_ANIME_SOFT"
    },
    "hands_style" => %{
      type: "categorical",
      options: [
        "HANDS_STYLE_NORMAL_HUMAN",
        "HANDS_STYLE_SUBTLY_STYLIZED"
      ],
      default: "HANDS_STYLE_NORMAL_HUMAN"
    },
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
    "HANDS_STYLE_NORMAL_HUMAN" => "Standard human hands with natural proportions and skin texture.",
    "HANDS_STYLE_SUBTLY_STYLIZED" => "Hands with slight artistic stylization while maintaining realistic proportions.",
    "FACE_STYLE_ANIME_SOFT" => "Soft anime-inspired facial features with large expressive eyes and gentle contours.",
    "FACE_STYLE_ANIME_SHARP_MATURE" => "Sharp, mature anime-inspired facial features with defined angles and sophisticated expression.",
    "FACE_STYLE_STYLIZED_NON_ANIME" => "Stylized facial features that are not specifically anime-inspired.",
    "HUMANOID_ARCHETYPE_HUMAN_FEATURED" => "Standard human facial and body features without animal characteristics.",
    "HUMANOID_ARCHETYPE_CAT_PERSON" => "Human-like form with feline characteristics such as ears, tail, and facial features.",
    "HUMANOID_ARCHETYPE_FOX_PERSON" => "Human-like form with fox characteristics such as ears, tail, and facial features.",
    "HUMANOID_ARCHETYPE_OTHER_KEMONOMIMI" => "Human-like form with animal characteristics from various species.",
    "KEMONOMIMI_EARS_TRUE" => "Visible animal ears as part of the character design.",
    "KEMONOMIMI_EARS_FALSE" => "No animal ears, standard human ear placement.",
    "KEMONOMIMI_TAIL_TRUE" => "Visible animal tail as part of the character design.",
    "KEMONOMIMI_TAIL_FALSE" => "No animal tail present.",
    "KEMONOMIMI_TAIL_STYLE_FLUFFY" => "A soft, fluffy tail typical of cats, foxes, or similar animals.",
    "KEMONOMIMI_TAIL_STYLE_SLEEK" => "A smooth, sleek tail design.",
    "KEMONOMIMI_TAIL_STYLE_SHORT_BOB" => "A short, bobbed tail that is compact and cute in appearance.",
    "KEMONOMIMI_TAIL_STYLE_LONG_FLOWING" => "A long and flowing animal tail.",
    "KEMONOMIMI_TAIL_STYLE_SEGMENTED_TECH" => "A mechanical or technological tail with segmented construction.",
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

  @doc "Returns the character slider configurations"
  def character_sliders, do: @character_sliders

  @doc "Returns the slider weights for weighted random selection"
  def slider_weights, do: @slider_weights

  @doc "Returns human-readable descriptions for character options"
  def option_descriptions, do: @option_descriptions

  @doc "Gets configuration for a specific slider"
  def get_slider_config(attribute), do: Map.get(@character_sliders, attribute)

  @doc "Gets weights for a specific slider"
  def get_slider_weights(attribute), do: Map.get(@slider_weights, attribute)

  @doc "Gets description for a specific option"
  def get_option_description(option), do: Map.get(@option_descriptions, option)
end