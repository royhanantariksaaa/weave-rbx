import path from "node:path"
import { createRequire } from "node:module"
import { fileURLToPath } from "node:url"
import { getBinaryPath } from "moonwave/dist/binary.js"

const require = createRequire(import.meta.url)
const siteDir = path.dirname(fileURLToPath(import.meta.url))
const projectDir = path.resolve(siteDir, "..")

function tailwindPlugin() {
  return {
    name: "tailwindcss-postcss",
    configurePostCss(postcssOptions) {
      postcssOptions.plugins.push(require("@tailwindcss/postcss"))
      return postcssOptions
    },
  }
}

export default async function createConfig() {
  const binaryPath = await getBinaryPath()

  return {
    title: "Weave",
    tagline: "Reactive Roblox UI with explicit ownership.",
    favicon: "mark.png",
    url: "https://royhanantariksaaa.github.io",
    baseUrl: "/weave-rbx/",
    organizationName: "royhanantariksaaa",
    projectName: "weave-rbx",
    onBrokenLinks: "warn",
    markdown: {
      hooks: {
        onBrokenMarkdownLinks: "warn",
      },
    },
    staticDirectories: [path.join(projectDir, ".moonwave", "static")],
    themes: [],
    themeConfig: {
      image: "logo.png",
      metadata: [{ name: "theme-color", content: "#087f5b" }],
      colorMode: {
        defaultMode: "dark",
        respectPrefersColorScheme: true,
      },
      prism: {
        additionalLanguages: ["lua", "bash", "css", "javascript", "diff", "git", "json", "typescript", "toml"],
      },
      navbar: {
        title: "Weave",
        logo: { alt: "Weave", src: "mark.png" },
        items: [
          { type: "doc", docId: "intro", label: "Docs", position: "left" },
          { to: "/api/", label: "API", position: "left" },
          { to: "/docs/playground", label: "Playground", position: "left" },
          { href: "https://royhanantariksaaa.github.io/echo-rbx/", label: "Echo", position: "right" },
          { href: "https://royhanantariksaaa.github.io/weavekit-rbx/", label: "WeaveKit", position: "right" },
          { href: "https://royhanantariksaaa.github.io/flite-rbx/", label: "Flite", position: "right" },
          { href: "https://github.com/royhanantariksaaa/weave-rbx", label: "GitHub", position: "right" },
        ],
      },
      footer: {
        style: "dark",
        links: [
          {
            title: "Libraries",
            items: [
              { label: "Echo", href: "https://royhanantariksaaa.github.io/echo-rbx/" },
              { label: "WeaveKit", href: "https://royhanantariksaaa.github.io/weavekit-rbx/" },
              { label: "Flite", href: "https://royhanantariksaaa.github.io/flite-rbx/" },
            ],
          },
          {
            title: "Credits",
            items: [{ label: "Streamline Core icons (CC BY 4.0)", href: "https://streamlinehq.com" }],
          },
        ],
        copyright: "Weave documentation. Built with shadcn/ui, Moonwave, and Docusaurus.",
      },
    },
    plugins: [
      tailwindPlugin,
      [
        "docusaurus-plugin-moonwave",
        {
          id: "moonwave",
          code: [path.join(projectDir, "docs-api")],
          sourceUrl: "https://github.com/royhanantariksaaa/weave-rbx/blob/main",
          projectDir,
          classOrder: [
            "Weave",
            "Scope",
            "State",
            "AnimationState",
            "AsyncResult",
            "Context",
            "Ref",
            "LazyRef",
            "Components",
            "Form",
            "Store",
            "Resource",
            "History",
            "Queue",
            "DragState",
            "GestureState",
            "FloatState",
            "AnimationController",
            "LayoutController",
          ],
          apiCategories: [],
          binaryPath,
        },
      ],
      "docusaurus-lunr-search",
    ],
    presets: [
      [
        "@docusaurus/preset-classic",
        {
          docs: {
            path: path.join(projectDir, "docs"),
            editUrl: "https://github.com/royhanantariksaaa/weave-rbx/edit/main/",
            sidebarCollapsible: true,
            sidebarPath: path.join(projectDir, ".moonwave", "sidebars.js"),
          },
          blog: false,
          pages: { path: path.join(projectDir, "pages"), exclude: ["_*.*"] },
          theme: {
            customCss: [path.join(projectDir, ".moonwave", "custom.css"), "./src/css/globals.css"],
          },
        },
      ],
    ],
  }
}
