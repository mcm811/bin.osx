#!/bin/bash

rsync -auzv --delete ~/Documents/ /Volumes/Backup.localized/Sync.localized/Documents
rsync -auzv --delete ~/OneDrive/ /Volumes/Backup.localized/Sync.localized/OneDrive
rsync -auzv --delete ~/"Google Drive"/ /Volumes/Backup.localized/Sync.localized/"Google Drive"
rsync -auzv --delete ~/Developer.localized/ /Volumes/Backup.localized/Sync.localized/Developer.localized
rsync -auzv --delete ~/Archives.localized/ /Volumes/Backup.localized/Archives.localized

rsync -auzv /Volumes/Backup.localized/Archives.localized/ ~/Archives.localized