fs = require('fs')

function copy(from, to) {
    fs.createReadStream(from).pipe(fs.createWriteStream(to))
}

function copyDir(inDir, outDir) {
    var files = fs.readdirSync(inDir);
    for (var i = 0; i < files.length; ++i) {
        if(fs.statSync(inDir + "/" + files[i]).isDirectory()) {
            copyDir(inDir + "/" + files[i], outDir);
        }
    }
    for (var i = 0; i < files.length; ++i) {
        console.log(files[i])
        if (files[i].indexOf('.js') == files[i].length - 3) {
            copy(inDir + '/' + files[i], outDir+'/'+files[i]);
        }
    }
}

var inDir = process.argv[2];
var outDir = process.argv[3];
copyDir(inDir, outDir)