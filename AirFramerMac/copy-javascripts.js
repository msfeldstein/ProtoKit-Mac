fs = require('fs')
var inDir = process.argv[2];
var outDir = process.argv[3];
var files = fs.readdirSync(inDir);
for (var i = 0; i < files.length; ++i) {
    if (files[i].indexOf('.js') == files[i].length - 3) {
        fs.createReadStream(inDir + '/' + files[i]).pipe(fs.createWriteStream(outDir+'/'+files[i]))
    }
}