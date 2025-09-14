# Script to copy moduledoc from ExBags to README.md

defmodule ModuledocToReadme do
  @moduledoc """
  Copies the @moduledoc from ExBags module to README.md file.
  """

  def copy_moduledoc_to_readme do
    IO.puts("📝 Copying moduledoc from ExBags to README.md...")

    # Read the source file and extract moduledoc
    source_file = "lib/ex_bags.ex"

    if File.exists?(source_file) do
      content = File.read!(source_file)
      moduledoc = extract_moduledoc(content)

      if moduledoc do
        # Convert moduledoc to README format
        readme_content = format_moduledoc_as_readme(moduledoc)

        # Write to README.md
        File.write!("README.md", readme_content)

        IO.puts("✅ Successfully copied moduledoc to README.md")
      else
        IO.puts("❌ No moduledoc found in ExBags module")
      end
    else
      IO.puts("❌ Source file not found: #{source_file}")
    end
  end

  defp extract_moduledoc(content) do
    # Find the @moduledoc section
    case Regex.run(~r/@moduledoc\s+"""\s*\n(.*?)\s*"""/s, content) do
      [_, moduledoc] -> moduledoc
      _ -> nil
    end
  end

  defp format_moduledoc_as_readme(moduledoc) do
    # The moduledoc is already in the correct format for README
    # Just add the title
    "# ExBags\n\n" <> moduledoc
  end
end

# Run the copy operation
ModuledocToReadme.copy_moduledoc_to_readme()
