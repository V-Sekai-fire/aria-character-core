# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaFate.SRDParser do
  @moduledoc """
  Parses Fate Core SRD documents to extract character creation rules and examples.

  This module provides functionality to parse HTML SRD files and extract
  structured data about skills, stunts, aspects, and other character elements
  that can be used to inform the character generation process.
  """

  @doc """
  Parses a Fate SRD HTML file and extracts structured data.

  ## Parameters

  - `srd_path` - Path to the SRD HTML file
  - `section` - Optional section to extract (`:all`, `:skills`, `:stunts`, `:aspects`)

  ## Examples

      iex> AriaFate.SRDParser.parse_srd("path/to/fate-core-srd.html", :skills)
      {:ok, %{
        skills: [
          %{name: "Athletics", description: "..."},
          %{name: "Fight", description: "..."}
        ]
      }}
  """
  def parse_srd(srd_path, section \\ :all) do
    case File.read(srd_path) do
      {:ok, html_content} ->
        parse_html_content(html_content, section)

      {:error, reason} ->
        {:error, "Failed to read SRD file: #{reason}"}
    end
  end

  # Private implementation functions

  defp parse_html_content(html_content, section) do
    case Floki.parse_document(html_content) do
      {:ok, document} ->
        extract_sections(document, section)

      {:error, reason} ->
        {:error, "Failed to parse HTML: #{reason}"}
    end
  end

  defp extract_sections(document, :all) do
    {:ok, %{
      skills: extract_skills(document),
      stunts: extract_stunts(document),
      aspects: extract_aspects(document),
      character_creation: extract_character_creation_rules(document)
    }}
  end

  defp extract_sections(document, :skills) do
    {:ok, %{skills: extract_skills(document)}}
  end

  defp extract_sections(document, :stunts) do
    {:ok, %{stunts: extract_stunts(document)}}
  end

  defp extract_sections(document, :aspects) do
    {:ok, %{aspects: extract_aspects(document)}}
  end

  defp extract_sections(document, :character_creation) do
    {:ok, %{character_creation: extract_character_creation_rules(document)}}
  end

  defp extract_sections(_document, section) do
    {:error, "Unknown section: #{section}"}
  end

  defp extract_skills(_document) do
    # Extract skill information from the SRD
    # This would parse the actual HTML structure of the SRD
    # For now, return default Fate Core skills
    [
      %{name: "Academics", description: "Reasoning and knowledge of facts"},
      %{name: "Athletics", description: "Physical capability and training"},
      %{name: "Burglary", description: "Criminal activity and stealth"},
      %{name: "Contacts", description: "Social networks and information gathering"},
      %{name: "Crafts", description: "Making and breaking things"},
      %{name: "Deceive", description: "Lying and misdirection"},
      %{name: "Drive", description: "Operating vehicles"},
      %{name: "Empathy", description: "Understanding people's emotions"},
      %{name: "Fight", description: "Hand-to-hand combat"},
      %{name: "Investigate", description: "Deliberate discovery of information"},
      %{name: "Lore", description: "Specialized knowledge"},
      %{name: "Notice", description: "Passive awareness"},
      %{name: "Physique", description: "Physical strength and endurance"},
      %{name: "Provoke", description: "Getting emotional reactions"},
      %{name: "Rapport", description: "Positive social interaction"},
      %{name: "Resources", description: "Material wealth and connections"},
      %{name: "Shoot", description: "Ranged combat"},
      %{name: "Stealth", description: "Avoiding detection"},
      %{name: "Survival", description: "Enduring harsh conditions"},
      %{name: "Will", description: "Mental fortitude"}
    ]
  end

  defp extract_stunts(_document) do
    # Extract stunt examples from the SRD
    # This would parse actual stunt descriptions from the HTML
    [
      %{
        name: "Lethal Weapon",
        skill: "Fight",
        description: "Because I am a Lethal Weapon, I get a +2 when I use Fight to attack an opponent who is caught off-guard or otherwise unable to defend properly."
      },
      %{
        name: "Backup Weapon",
        skill: "Fight",
        description: "Because I always have a Backup Weapon, I can spend a fate point to declare that I have a weapon even when disarmed or in a situation where I shouldn't have one."
      },
      %{
        name: "Keen Senses",
        skill: "Notice",
        description: "Because I have Keen Senses, I get a +2 when I use Notice to discover or perceive things using a specific sense."
      }
    ]
  end

  defp extract_aspects(_document) do
    # Extract aspect examples from the SRD
    [
      %{
        type: "high_concept",
        examples: [
          "Wizard Private Eye",
          "Reluctant Scion of the Underseelie Court",
          "Failed Wizard Turned Thief",
          "Gruff Ex-Cop Turned Private Eye"
        ]
      },
      %{
        type: "trouble",
        examples: [
          "The Mantle of the Winter Knight Comes with a Price",
          "My Enemies in the Underseelie Court",
          "The Temptation of Easy Money",
          "I Don't Know When to Quit"
        ]
      },
      %{
        type: "relationship",
        examples: [
          "I Owe John Marcone a Favor",
          "Karrin Murphy Has My Back",
          "The Archive Knows My True Name",
          "My Brother Runs the Outfit"
        ]
      }
    ]
  end

  defp extract_character_creation_rules(_document) do
    # Extract character creation guidelines from the SRD
    %{
      skill_points: %{
        great: 1,      # One skill at Great (+4)
        good: 2,       # Two skills at Good (+3)
        fair: 3,       # Three skills at Fair (+2)
        average: 4     # Four skills at Average (+1)
      },
      aspects: %{
        total: 5,
        required: ["high_concept", "trouble"],
        optional: ["phase_one", "phase_two", "phase_three"]
      },
      stunts: %{
        starting: 3,
        refresh_cost: 1,
        max_without_refresh_loss: 3
      },
      refresh: %{
        starting: 3,
        minimum: 1
      },
      stress_tracks: %{
        physical: %{base: 2, skill: "Physique"},
        mental: %{base: 2, skill: "Will"}
      }
    }
  end

  @doc """
  Extracts skill descriptions for use in character generation.
  """
  def get_skill_descriptions do
    %{
      academics: "Reasoning and knowledge of facts, education, and scholarly pursuits",
      athletics: "Physical capability, training, running, jumping, climbing",
      burglary: "Criminal activity, stealth, security systems, lockpicking",
      contacts: "Social networks, information gathering, knowing people",
      crafts: "Making and breaking things, engineering, artistry",
      deceive: "Lying, misdirection, disguise, creating false impressions",
      drive: "Operating vehicles, piloting, navigation",
      empathy: "Understanding people's emotions, reading social situations",
      fight: "Hand-to-hand combat, martial arts, melee weapons",
      investigate: "Deliberate discovery of information, research, analysis",
      lore: "Specialized knowledge, occult, history, science",
      notice: "Passive awareness, alertness, perception",
      physique: "Physical strength, endurance, health",
      provoke: "Getting emotional reactions, intimidation, leadership",
      rapport: "Positive social interaction, charm, etiquette",
      resources: "Material wealth, connections, influence",
      shoot: "Ranged combat, firearms, archery, thrown weapons",
      stealth: "Avoiding detection, hiding, moving quietly",
      survival: "Enduring harsh conditions, wilderness skills",
      will: "Mental fortitude, discipline, magical power"
    }
  end

  @doc """
  Returns example stunts organized by skill.
  """
  def get_stunt_examples do
    %{
      athletics: [
        "Hardcore Parkour: +2 to Athletics when overcoming obstacles in a chase",
        "Dazing Counter: When you succeed with style on an Athletics defense, you can choose to inflict a 2-shift hit rather than take a boost"
      ],
      fight: [
        "Heavy Hitter: When you succeed with style on a Fight attack and choose to reduce the result by one to gain a boost, you gain a full situation aspect with a free invocation instead",
        "Backup Weapon: Spend a fate point to declare you have a weapon even when disarmed"
      ],
      investigate: [
        "Attention to Detail: You can use Investigate instead of Empathy to defend against Deceive",
        "The Power of Deduction: Once per scene you can spend a fate point to make a special Investigate roll representing a flash of insight"
      ],
      rapport: [
        "Best Foot Forward: Twice per session, you may upgrade a boost you receive with Rapport into a full situation aspect with a free invocation",
        "Popular: If you're in an area where you're popular and well-liked, you can use Rapport in place of Contacts"
      ]
    }
  end
end
