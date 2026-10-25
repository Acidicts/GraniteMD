import { Controller } from "@hotwired/stimulus";

// Quick switcher for the workspace page (Ctrl+K, Cmd+K on a Mac).
//
// The search has two halves that meet in one result list:
//   * titles are fuzzy-matched in the browser against the page index the
//     server rendered into the page, so results appear on the keystroke
//     with no round trip;
//   * page bodies are searched by Postgres (tsvector + GIN index) through
//     the search endpoint, so a word that only appears inside a page still
//     finds it.
//
// Workspace files are listed next to the pages: they have no body to
// search, so they are matched by name like the pages are.
//
// Both halves produce the same shape, so the list can merge them and drop
// the duplicates.
export default class extends Controller {
  static targets = ["dialog", "input", "results", "empty"];
  static values = {
    pages: { type: Object, default: {} },
    files: { type: Array, default: [] },
    searchUrl: { type: String, default: "" },
    indexUrl: { type: String, default: "" },
  };

  connect() {
    this._entries = this.buildIndex(this.pagesValue, this.filesValue);
    this._content = [];
    this._results = [];
    this._active = 0;
    this._timer = null;
    this._request = 0;

    this._shortcut = (event) => this.onShortcut(event);
    document.addEventListener("keydown", this._shortcut);
  }

  disconnect() {
    document.removeEventListener("keydown", this._shortcut);
    clearTimeout(this._timer);
  }

  // Ctrl+K opens the switcher, pressing it again closes it. Key auto-repeat
  // must not toggle it, so it is ignored outright.
  onShortcut(event) {
    if (!(event.metaKey || event.ctrlKey)) return;
    if (event.key.toLowerCase() !== "k") return;
    if (event.repeat) return;
    event.preventDefault();
    if (this.isOpen()) {
      this.close();
    } else {
      this.open();
    }
  }

  open() {
    if (!this.hasDialogTarget) return;
    if (this.isOpen()) return;

    this._content = [];
    this._active = 0;
    this._timer = null;
    // Answers for an older query (or from before this dialog opened) must
    // not land now that the list has been reset.
    this._request += 1;
    if (this.hasInputTarget) this.inputTarget.value = "";
    this.render();
    this.dialogTarget.showModal();
    // After showModal, so the caret does not land on a display:none input.
    if (this.hasInputTarget) this.inputTarget.focus();
    // The rendered index can be behind the tree (a page created or renamed
    // since this page was loaded), so pick up a fresh one in the back.
    this.refreshIndex();
  }

  close() {
    clearTimeout(this._timer);
    this._timer = null;
    if (this.hasDialogTarget && this.dialogTarget.open) this.dialogTarget.close();
  }

  isOpen() {
    return this.hasDialogTarget && this.dialogTarget.open;
  }

  // The panel fills the dialog, so a click that reaches the dialog itself
  // is by definition on the backdrop the browser draws behind it.
  backdrop(event) {
    if (event.target !== this.dialogTarget) return;
    this.close();
  }

  // Typing: the fuzzy titles are filtered straight away, the body search
  // follows once the typing settles down.
  search() {
    // Anything answered before this keystroke is now stale: its response
    // must not render under the new query.
    this._request += 1;
    const query = this.query();

    this._content = [];
    this._active = 0;
    this.render();

    clearTimeout(this._timer);
    if (!query) return;
    this._timer = setTimeout(() => this.fetchContent(query), 150);
  }

  navigate(event) {
    const count = this._results.length;

    if (event.key === "ArrowDown") {
      event.preventDefault();
      this.setActive(count === 0 ? 0 : (this._active + 1) % count);
    } else if (event.key === "ArrowUp") {
      event.preventDefault();
      this.setActive(count === 0 ? 0 : (this._active - 1 + count) % count);
    } else if (event.key === "Home") {
      event.preventDefault();
      this.setActive(0);
    } else if (event.key === "End") {
      event.preventDefault();
      this.setActive(Math.max(0, count - 1));
    } else if (event.key === "Enter") {
      event.preventDefault();
      this.activeLink()?.click();
    }
  }

  query() {
    if (!this.hasInputTarget) return "";
    return this.inputTarget.value.trim();
  }

  // The pages and the files of the workspace, in the shape the fuzzy
  // matcher works with.
  buildIndex(pages, files) {
    return [ ...buildPageEntries(pages), ...buildFileEntries(files) ];
  }

  // ---------- Data ----------

  async refreshIndex() {
    if (!this.indexUrlValue) return;

    try {
      const response = await fetch(this.indexUrlValue, {
        headers: { Accept: "application/json" },
      });
      if (!response.ok) return;
      const data = await response.json();
      const pages = data && data.pages ? data.pages : {};
      const files = (data && data.files) || [];
      this._entries = this.buildIndex(pages, files);
      this.render();
    } catch {
      // Keep the index we already have: the fuzzy titles still work.
    }
  }

  async fetchContent(query) {
    if (!this.searchUrlValue) return;

    const request = ++this._request;
    try {
      const response = await fetch(`${this.searchUrlValue}?q=${encodeURIComponent(query)}`, {
        headers: { Accept: "application/json" },
      });
      if (!response.ok) return;
      const data = await response.json();
      // A newer query has been typed since: its answer wins.
      if (request !== this._request) return;
      this._content = (data && data.results) || [];
      this.render();
    } catch {
      // The fuzzy titles are still on screen.
    }
  }

  // ---------- Rendering ----------

  collect(query) {
    // Without a query every page is offered, by name: the list is then a
    // short browse of the workspace instead of a last-used order.
    const fuzzy = query === ""
      ? this._entries
          .map((entry) => ({ entry, score: 0, positions: [], field: "name" }))
          .sort((a, b) => a.entry.name.localeCompare(b.entry.name))
          .slice(0, 20)
      : this._entries
          .map((entry) => scoreEntry(entry, query))
          .filter((match) => match !== null)
          .sort((a, b) => b.score - a.score || a.entry.name.localeCompare(b.entry.name))
          .slice(0, 20);

    const seen = new Set(fuzzy.map((match) => match.entry.url));
    const content = this._content
      .filter((result) => !seen.has(result.url))
      .map((result) => ({
        entry: {
          id: result.id,
          url: result.url,
          name: result.name,
          kind: "page",
          folder: folderOf(result.path, result.name),
          path: result.path,
        },
        score: 0,
        positions: [],
        field: "name",
        snippet: result.snippet,
      }));

    // The same page can be both a title match and a body match; keep the
    // single row and fold the body snippet into it so the context is not lost.
    for (const result of this._content) {
      const match = fuzzy.find((entry) => entry.entry.url === result.url);
      if (match) match.snippet = result.snippet;
    }

    return [ ...fuzzy, ...content ];
  }

  render() {
    if (!this.hasResultsTarget) return;

    const query = this.query();
    const results = this.collect(query);
    this._results = results;
    if (this._active >= results.length) this._active = Math.max(0, results.length - 1);

    const list = this.resultsTarget;
    list.innerHTML = "";

    results.forEach((match, index) => {
      const link = document.createElement("a");
      link.className = "workspace-switcher__result";
      link.href = match.entry.url;
      link.id = `workspace-switcher-result-${index}`;
      link.dataset.index = String(index);
      link.dataset.turboFrame = "workspace-editor";
      link.setAttribute("role", "option");
      link.setAttribute("aria-selected", index === this._active ? "true" : "false");
      if (index === this._active) link.classList.add("workspace-switcher__result--active");

      const name = document.createElement("span");
      name.className = "workspace-switcher__result-name";
      const primary = match.field === "path" ? match.entry.path : match.entry.name;
      appendHighlighted(name, primary, match.positions, match.field === "path" ? "" : query);
      link.appendChild(name);

      if (match.field !== "path" && match.entry.folder) {
        const folder = document.createElement("span");
        folder.className = "workspace-switcher__result-folder";
        folder.textContent = match.entry.folder;
        link.appendChild(folder);
      }

      if (match.snippet) {
        const snippet = document.createElement("span");
        snippet.className = "workspace-switcher__result-snippet";
        appendHighlighted(snippet, match.snippet, [], query);
        link.appendChild(snippet);
      }

      link.addEventListener("click", () => this.choose(match));
      list.appendChild(link);
    });

    if (this.hasEmptyTarget) this.emptyTarget.hidden = results.length > 0;
    if (this.hasInputTarget) {
      this.inputTarget.setAttribute("aria-expanded", results.length > 0 ? "true" : "false");
      if (results.length > 0) {
        this.inputTarget.setAttribute("aria-activedescendant", `workspace-switcher-result-${this._active}`);
      } else {
        this.inputTarget.removeAttribute("aria-activedescendant");
      }
    }
  }

  setActive(index) {
    this._active = index;
    const options = this.hasResultsTarget ? [...this.resultsTarget.children] : [];
    options.forEach((option, position) => {
      const active = position === index;
      option.classList.toggle("workspace-switcher__result--active", active);
      option.setAttribute("aria-selected", active ? "true" : "false");
    });
    if (this.hasInputTarget) {
      if (options[index]) {
        this.inputTarget.setAttribute("aria-activedescendant", options[index].id);
      } else {
        this.inputTarget.removeAttribute("aria-activedescendant");
      }
    }
    options[index]?.scrollIntoView({ block: "nearest" });
  }

  activeLink() {
    if (!this.hasResultsTarget) return null;
    return this.resultsTarget.querySelector(".workspace-switcher__result--active");
  }

  // Open the page or file: the link navigates the editor frame, the
  // explorer is told about it so the tree highlights the row that was
  // opened.
  choose(match) {
    this.close();
    if (!match || !match.entry) return;
    document.dispatchEvent(
      new CustomEvent("workspace:open-page", {
        detail: { id: match.entry.id, kind: match.entry.kind },
      })
    );
  }
}

// ---------- Helpers ----------

// The page index is a map of every spelling of a page name to its URL:
// the bare name plus each folder path above it. Grouping by URL turns it
// back into one entry per page.
function buildPageEntries(map) {
  const byUrl = new Map();

  for (const [key, url] of Object.entries(map || {})) {
    let group = byUrl.get(url);
    if (!group) {
      group = [];
      byUrl.set(url, group);
    }
    group.push(key);
  }

  return [...byUrl.entries()].map(([url, keys]) => {
    const sorted = [ ...keys ].sort(
      (a, b) => a.split("/").length - b.split("/").length || a.length - b.length
    );
    // The shortest spelling is the page name, the longest the full path.
    const name = sorted[0];
    const full = sorted[sorted.length - 1];
    const nameParts = name.split("/");
    const fullParts = full.split("/");
    // The first segment of the full path is the workspace root: it is
    // named after the workspace, so it is left out of the folder shown.
    const folder = fullParts
      .slice(1, Math.max(1, fullParts.length - nameParts.length))
      .join("/");

    return {
      id: pageIdFromUrl(url),
      url,
      name,
      folder,
      path: folder ? `${folder}/${name}` : name,
      kind: "page",
    };
  });
}

// The files come from the server with their name, folder and preview URL
// already worked out: the map above only holds the spellings of a page
// name, which says nothing about a file.
function buildFileEntries(files) {
  return (files || []).map((file) => {
    const folder = file.folder || "";
    const name = file.name || "";

    return {
      id: file.id === undefined || file.id === null ? null : String(file.id),
      url: file.url,
      name,
      folder,
      path: folder ? `${folder}/${name}` : name,
      kind: "file",
    };
  });
}

function pageIdFromUrl(url) {
  const match = /\/pages\/(\d+)/.exec(url || "");
  return match ? match[1] : null;
}

function folderOf(path, name) {
  if (!path) return "";
  if (path === name) return "";
  return path.slice(0, path.length - name.length).replace(/\/$/, "");
}

// Score a page against the query. The name and the full path are tried
// separately so a match on either one counts, and the name wins ties.
function scoreEntry(entry, query) {
  const name = fuzzyMatch(query, entry.name);
  const path = entry.path ? fuzzyMatch(query, entry.path) : null;
  if (!name && !path) return null;

  const useName = Boolean(name) && (!path || name.score >= path.score);
  const match = useName ? name : path;

  return {
    entry,
    score: match.score + (useName ? 10 : 0),
    positions: match.positions,
    field: useName ? "name" : "path",
  };
}

// Subsequence match with a rough fzf-style score: every character of the
// query has to appear in the text, in order. Matches on a word boundary
// and matches right after the previous one score higher, so "ins" prefers
// "Install" over "Inspector".
function fuzzyMatch(query, text) {
  if (!query || !text) return null;

  const haystack = text.split("");
  const lowerHaystack = haystack.map((character) => character.toLowerCase());
  const positions = [];
  let score = 0;
  let index = 0;
  let previous = -2;

  for (const character of query) {
    const needle = character.toLowerCase();
    let found = -1;
    while (index < lowerHaystack.length) {
      if (lowerHaystack[index] === needle) {
        found = index;
        break;
      }
      index += 1;
    }
    if (found === -1) return null;

    const boundary = found === 0 || /[\s\-_/.,:()[\]]/.test(lowerHaystack[found - 1]);
    const consecutive = found === previous + 1;
    score += 10;
    if (boundary) score += 8;
    if (consecutive) score += 6;
    // A gap costs, but only a little: the first match of a long name
    // should not be punished too hard.
    score -= Math.min(found - (previous + 1), 5);
    positions.push(found);
    previous = found;
    index = found + 1;
  }

  // A whole-substring hit and a short name both win.
  if (lowerHaystack.join("").includes(query.toLowerCase())) score += 20;
  score -= Math.floor(text.length / 12);

  return { score, positions };
}

// Write text into an element, wrapping the matched characters in <mark>.
// The nodes are built by hand, so the text can never be read as markup.
function appendHighlighted(parent, text, positions, query = "") {
  const marks = positions && positions.length > 0
    ? positions
    : query ? queryPositions(text, query) : [];

  if (marks.length === 0) {
    parent.appendChild(document.createTextNode(text));
    return;
  }

  let cursor = 0;
  marks.forEach((position) => {
    // Overlapping matches (the same character found twice) are skipped.
    if (position < cursor || position >= text.length) return;
    if (position > cursor) parent.appendChild(document.createTextNode(text.slice(cursor, position)));
    const mark = document.createElement("mark");
    mark.textContent = text[position];
    parent.appendChild(mark);
    cursor = position + 1;
  });
  if (cursor < text.length) parent.appendChild(document.createTextNode(text.slice(cursor)));
}

// Every place the query words show up in the text (used for the body
// snippet, where the server does not say which characters matched).
function queryPositions(text, query) {
  const words = query.toLowerCase().split(/[^a-z0-9]+/).filter(Boolean);
  if (words.length === 0) return [];

  const positions = [];
  const lower = text.toLowerCase();
  words.forEach((word) => {
    let from = 0;
    let found = lower.indexOf(word, from);
    while (found !== -1) {
      for (let offset = 0; offset < word.length; offset += 1) positions.push(found + offset);
      from = found + word.length;
      found = lower.indexOf(word, from);
    }
  });
  return positions.sort((a, b) => a - b);
}
