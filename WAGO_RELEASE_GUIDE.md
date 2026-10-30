# Wago Addons Release Guide

This document outlines the end-to-end process for publishing and updating **OldSchoolConsumables** on [Wago Addons](https://addons.wago.io/) using automated GitHub Actions CI with [BigWigs Packager](https://github.com/BigWigsMods/packager), as well as manual fallback uploads.

---

## Overview

The standard release pipeline leverages:
- **TOC Metadata (`## X-Wago-ID`)**: Identifies the target project on Wago Addons.
- **BigWigs Packager (`BigWigsMods/packager`)**: Packages the addon directory into a clean distribution zip, strips development files (tests, dev tools), and deploys the build artifact to Wago Addons via API.
- **GitHub Actions Tag Triggers**: Automatically executes packaging and deployment whenever a semantic git tag (e.g. `v1.0.0`) is pushed.

---

## Step 1: Register Addon on Wago Addons

1. Navigate to [https://addons.wago.io/](https://addons.wago.io/) and log in (via Battle.net, Discord, or GitHub).
2. Click **Create Addon** or visit [https://addons.wago.io/addons/create](https://addons.wago.io/addons/create).
3. Fill in the project details:
   - **Name**: `OldSchoolConsumables`
   - **Category**: `Audio` or `Combat / Audio`
   - **Supported Game Versions**: World of Warcraft Retail / Midnight (12.0.0, 12.0.5)
   - **Short Description**: Authentic Old School RuneScape eating and drinking sound effects for World of Warcraft: Midnight (12.0+).
4. After submission, Wago assigns an **8-character alphanumeric Project ID** (e.g., `rN4Vk26D` or `7GKn9X6a`).
5. Copy this **Wago Project ID** for Step 2.

---

## Step 2: Configure Addon TOC Metadata

Open `OldSchoolConsumables.toc` and add the `X-Wago-ID` directive:

```toc
## Interface: 120100, 120105
## Title: |cffffd100OldSchoolConsumables|r
## Notes: Plays authentic Old School RuneScape drinking and eating sound effects when using consumables.
## Author: OldSchoolConsumables Team
## Version: 1.0.0
## SavedVariables: OldSchoolConsumablesDB
## IconTexture: Interface\Icons\INV_Potion_51
## Category: Audio
## X-Wago-ID: <WAGO_PROJECT_ID>
```

> [!IMPORTANT]
> Replace `<WAGO_PROJECT_ID>` with the exact 8-character ID obtained from Step 1. BigWigs Packager automatically inspects the `.toc` file for `## X-Wago-ID:`. If this tag is missing, Wago deployment is skipped by the packager.

---

## Step 3: Configure GitHub Actions Secrets

To allow GitHub Actions to authenticate with Wago Addons:

1. In Wago Addons, navigate to your **Account Settings** -> **API Tokens** (or [https://addons.wago.io/account](https://addons.wago.io/account)).
2. Generate a new API token with **Addon Upload / Manage** permissions.
3. Open your GitHub repository in a browser:
   - Go to **Settings** -> **Secrets and variables** -> **Actions**.
   - Click **New repository secret**.
   - **Name**: `WAGO_API_TOKEN`
   - **Value**: Paste the API token from Wago.
   - Click **Add secret**.

*(Optional)* If publishing to CurseForge as well, configure `CF_API_KEY` following the same pattern with `## X-Curse-Project-ID:` in the TOC.

---

## Step 4: Automated Publishing via Git Tags

The repository includes a GitHub Actions workflow (`.github/workflows/release.yml`) configured with `BigWigsMods/packager@v2`.

### Triggering a Release

1. Verify all code changes and increment the `## Version:` field in `OldSchoolConsumables.toc` and `CHANGELOG.md`.
2. Commit and tag the repository:
   ```bash
   git add .
   git commit -m "Release v1.0.0: Midnight 12.0+ sound replacement"
   git tag v1.0.0
   git push origin main --tags
   ```
3. GitHub Actions triggers automatically:
   - Checks out the repository.
   - Executes BigWigs Packager.
   - Reads `.pkgmeta` to package addon assets and exclude development files.
   - Uploads `OldSchoolConsumables-v1.0.0.zip` to GitHub Releases.
   - Deploys the package to Wago Addons using `WAGO_API_TOKEN` and `X-Wago-ID`.

---

## Step 5: Manual Upload Alternative

If GitHub Actions CI is not used, or if an urgent manual patch must be deployed directly:

### 1. Build the Distribution Archive

WoW addon archives **must** contain an internal `OldSchoolConsumables/` top-level directory to prevent file sprawl into the player's `Interface\AddOns` folder.

#### Option A: Python Packaging Tool (Recommended)
Run the automated release packaging script, which strictly enforces the `OldSchoolConsumables/` internal directory hierarchy, validates CRC-32 integrity, and excludes development files:

```bash
# From the repository root:
python projects/old-school-consumables/tools/build_release_zip.py
```

#### Option B: PowerShell Staging Command
If Python is unavailable, stage the distribution files into a temporary `OldSchoolConsumables` folder before compressing:

```powershell
# From the repository root:
$StageDir = "dist\staging\OldSchoolConsumables"
New-Item -ItemType Directory -Force -Path "$StageDir\Sounds" | Out-Null
Copy-Item projects\old-school-consumables\*.lua, projects\old-school-consumables\*.toc -Destination $StageDir
Copy-Item projects\old-school-consumables\Sounds\* -Destination "$StageDir\Sounds"
Compress-Archive -Path "dist\staging\OldSchoolConsumables" -DestinationPath "dist\OldSchoolConsumables-v1.0.0.zip" -Force
Remove-Item "dist\staging" -Recurse -Force
```

### 2. Upload via Wago Dashboard

1. Log in to [https://addons.wago.io/](https://addons.wago.io/).
2. Select **OldSchoolConsumables** from your dashboard.
3. Click **New Version** or **Upload Release**.
4. Attach `dist/OldSchoolConsumables-v1.0.0.zip`.
5. Specify:
   - **Release Type**: `Release` (or `Beta` / `Alpha`)
   - **Game Version**: `12.0.0, 12.0.5 (Retail)`
   - **Changelog**: Copy the latest section from `CHANGELOG.md`.
6. Submit the release. It will immediately become available in the Wago App and web catalog.
