#!/bin/bash

# simplescreenrecorder --help
# Usage: simplescreenrecorder [OPTIONS]

# Options:
#   --help                Show this help message.
#   --version             Show version information.
#   --settingsfile=FILE   Load and save program settings to FILE. If omitted,
#                         ~/.ssr/settings.conf is used.
#   --logfile[=FILE]      Write log messages to FILE. If FILE is omitted,
#                         ~/.ssr/log-DATE_TIME.txt is used.
#   --statsfile[=FILE]    Write recording statistics to FILE. If FILE is omitted,
#                         /dev/shm/simplescreenrecorder-stats-PID is used. It will
#                         be updated continuously and deleted when the recording
#                         page is closed.
#   --no-systray          Don't show the system tray icon.
#   --start-hidden        Start the application in hidden form.
#   --start-recording     Start the recording immediately.
#   --activate-schedule   Activate the recording schedule immediately.
#   --syncdiagram         Show synchronization diagram (for debugging).
#   --benchmark           Run the internal benchmark.

# Commands accepted through stdin:
#   record-start          Start the recording.
#   record-pause          Pause the recording.
#   record-cancel         Cancel the recording and delete the output file.
#   record-save           Finish the recording and save the output file.
#   schedule-activate     Activate the recording schedule.
#   schedule-deactivate   Deactivate the recording schedule.
#   window-show           Show the application window.
#   window-hide           Hide the application window.
#   quit                  Quit the application.