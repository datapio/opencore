import babel from '@rollup/plugin-babel'


export default {
  input: `tests/index.js`,
  output: {
    file: 'dist/tests.js',
    format: 'cjs',
    sourcemap: true
  },
  plugins: [babel()]
}
