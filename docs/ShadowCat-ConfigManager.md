![Mr Robot fonts](https://see.fontimg.com/api/renderfont4/g123/eyJyIjoiZnMiLCJoIjoxMjUsInciOjE1MDAsImZzIjo4MywiZmdjIjoiI0VGMDkwOSIsImJnYyI6IiMxMTAwMDAiLCJ0IjoxfQ/cyBoIGEgZCBvIHcgYyBAIHQ=/mrrobot.png)

# ShadowCat-ConfigManager

## Overview

`ShadowCat-ConfigManager` is a PowerShell utility designed to help users manage, validate, and analyze the modular JSON configuration files that power the ShadowCat Security Toolkit. It is essential for maintaining large, complex setups and for customizing tool profiles to fit specific security needs.

## Key Features

- **Configuration Validation**: Ensures your JSON config files are syntactically correct and contain all required metadata.
- **Dependency Analysis**: Visualizes and checks the dependency chain between configuration files, preventing circular dependencies and missing requirements.
- **Tool Listing**: Lists all tools that would be installed from a given configuration, including those pulled in via dependencies.
- **Dry Run Support**: Preview what would be installed without making any changes to your system.
- **Custom Profile Creation**: Assists in building new configuration files for custom toolsets or specialized workflows.

## Typical Usage


### Validate a Configuration File
```powershell
. ./ShadowCat-ConfigManager.ps1 -Action validate -ConfigFile configs\shadowcat-web-tools.json
```
Checks the syntax and required fields of the specified config file.

### List All Tools in a Config
```powershell
. ./ShadowCat-ConfigManager.ps1 -Action list -ConfigFile configs\shadowcat-redteam-tools.json
```
Displays a complete list of tools that will be installed, including those from dependencies.

### Create a Custom Config
```powershell
. ./ShadowCat-ConfigManager.ps1 -Action create-config -ConfigFile configs\my-custom-profile.json
```
Guides you through creating a new config file, optionally starting from an existing base.

### Merge Configs
```powershell
. ./ShadowCat-ConfigManager.ps1 -Action merge-configs -MergeConfigs configs\one.json,configs\two.json -OutputConfig configs\merged.json
```
Combines multiple config files into one output config.

## How It Works

- **Validation**: Parses the JSON, checks for required fields (`metadata`, `chocolatey`, etc.), and reports errors or warnings.
- **Dependency Analysis**: Recursively reads the `dependencies` array in each config's metadata, building a full dependency graph.
- **Tool Listing**: Aggregates all tools from the main config and its dependencies, ensuring no duplicates (using `toolId`).
- **Custom Config Creation**: Prompts the user for tool details and builds a new JSON config interactively or from a template.

## Best Practices

- Always validate configs before running an installation.
- Use dependency analysis to avoid circular references and missing dependencies.
- Regularly update your custom profiles to include new tools and improvements.
- Share validated configs with the community for peer review and collaboration.

## Example Workflow
1. Validate your new config: `-ValidateConfig`
2. Analyze dependencies: `-AnalyzeDependencies`
3. Preview tool list: `-ListTools`
4. Create or edit configs: `-CreateConfig`
5. Run the installer with your validated config(s).

## Additional Resources
- See the main README for more on modular configuration.
- Refer to example configs in the `configs/` folder.
- For troubleshooting, use the dry run and validation features before installation.

---

*ShadowCat-ConfigManager is a vital tool for anyone customizing or maintaining a ShadowCat deployment. It ensures reliability, maintainability, and flexibility for all users, from beginners to advanced security professionals.*
