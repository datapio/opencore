import babel from '@rollup/plugin-babel'


export default {
  input: 'src/index.js',
  output: {
    file: 'dist/app.js',
    format: 'cjs'
  },
  plugins: [babel()]
}
