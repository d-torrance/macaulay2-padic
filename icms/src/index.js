import Reveal from "reveal.js";
import RevealMarkdown from "reveal.js/plugin/markdown/markdown.esm.js";
import RevealMath from "reveal.js/plugin/math/math.esm.js";
import RevealHighlight from "reveal.js/plugin/highlight/highlight.esm.js";
import "reveal.js/dist/reveal.css";
import "reveal.js/dist/theme/moon.css";
import "reveal.js/plugin/highlight/zenburn.css";
import macaulay2 from "highlightjs-macaulay2";
import "./style.css";

let deck = new Reveal({
  highlight: {
    beforeHighlight: (hljs) => hljs.registerLanguage("macaulay2", macaulay2),
  },
  plugins: [RevealMarkdown, RevealMath.KaTeX, RevealHighlight],
});
deck.initialize();
