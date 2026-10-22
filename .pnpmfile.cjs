// openapi-typescript drives the JavaScript compiler API (`ts.factory`), which TypeScript 7 (the
// native compiler the repo uses) does not provide yet. It gets a TypeScript 5 of its own instead of
// the workspace's 7; nothing else changes. Drop this once openapi-typescript supports TypeScript 7.
function readPackage(pkg) {
  if (pkg.name === "openapi-typescript") {
    delete pkg.peerDependencies?.typescript;
    pkg.dependencies = { ...pkg.dependencies, typescript: "5.9.3" };
  }
  return pkg;
}

module.exports = { hooks: { readPackage } };
