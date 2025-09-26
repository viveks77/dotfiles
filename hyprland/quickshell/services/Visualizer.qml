pragma Singleton
import QtQuick
import Quickshell.Io
import qs.modules.common

QtObject {
    id: root
    property list<real> points: []

    Component.onCompleted: {
        const processString = `
import Quickshell.Io 1.0
Process {
    id: cavaProc
    running: true
    command: ["cava", "-p", "${FileUtils.trimFileProtocol(Directories.scriptPath)}/cava/raw_output_config.txt"]
    stdout: SplitParser {
        onRead: data => {
            let parsedPoints = data.split(";").map(p => parseFloat(p.trim())).filter(p => !isNaN(p));
            root.points = parsedPoints;
        }
    }
    onRunningChanged: {
        if (!cavaProc.running) {
            root.points = [];
        }
    }
}`;
        let proc = Qt.createQmlObject(processString, root, "visualizerProc");
        if (!proc) {
            console.error("Error creating process for visualizer");
        }
    }
}
