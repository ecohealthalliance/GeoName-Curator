//const ExtractTextPlugin = require('extract-text-webpack-plugin');
//const PRODUCTION = process.argv[2] === '-p';
require('es6-promise').polyfill();

module.exports = {
    entry: './app.js',
    output: {
        filename: '../public/eidr-connect-post-enhancer.js'
    },
    module: {
        loaders: [
            { test: /\.js$/, exclude: /node_modules/, loader: 'babel' },
            { test: /\.css$/, loader: "style-loader!css-loader" }
        ],
    }
};