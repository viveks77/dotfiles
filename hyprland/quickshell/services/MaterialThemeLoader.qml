pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Automatically reloads generated material colors.
 * It is necessary to run reapplyTheme() on startup because Singletons are lazily loaded.
 */
Singleton {
    id: root
    property string filePath: Directories.generatedMaterialThemePath

    function reapplyTheme() {
        themeFileView.reload()
    }

    function applyColors(fileContent) {
        console.log("MaterialThemeLoader: Attempting to apply colors...")
        if (!fileContent || fileContent.trim() === "") {
            console.log("MaterialThemeLoader: File content is empty. Aborting.");
            return;
        }
        try {
            console.log("MaterialThemeLoader: Parsing JSON...");
            const json = JSON.parse(fileContent)
            console.log("MaterialThemeLoader: JSON parsed successfully. Applying colors...");
            for (const key in json) {
                if (json.hasOwnProperty(key)) {
                    // Convert snake_case to CamelCase
                    const camelCaseKey = key.replace(/_([a-z])/g, (g) => g[1].toUpperCase())
                    const m3Key = `m3${camelCaseKey}`
                    Appearance.m3colors[m3Key] = json[key]
                }
            }
            
            Appearance.m3colors.darkmode = (Appearance.m3colors.m3background.hslLightness < 0.5)
            console.log("MaterialThemeLoader: Colors applied. Dark mode:", Appearance.m3colors.darkmode);
        } catch (e) {
            console.error("MaterialThemeLoader: Failed to parse material theme JSON:", e)
            console.error("MaterialThemeLoader: File content was:", fileContent)
        }
    }

    Timer {
        id: delayedFileRead
        interval: Config.options?.hacks?.arbitraryRaceConditionDelay ?? 100
        repeat: false
        running: false
        onTriggered: {
            root.applyColors(themeFileView.text())
        }
    }

	FileView { 
        id: themeFileView
        path: Qt.resolvedUrl(root.filePath)
        watchChanges: true
        onFileChanged: {
            this.reload()
            delayedFileRead.start()
        }
        onLoadedChanged: {
            const fileContent = themeFileView.text()
            root.applyColors(fileContent)
        }
    }
}
