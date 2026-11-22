import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    static values = { path: String };
    static targets = ["paginator", "search_input"];

    connect() {
        this._reloadTimer = null;
    }

    search() {
        clearTimeout(this._reloadTimer);
        this._reloadTimer = setTimeout(() => this.reload(), 300);
    }

    reload() {
        const url = new URL(this.pathValue, window.location.origin);
        if (this.hasPaginatorTarget) {
            url.searchParams.set("paginator", this.paginatorTarget.value);
        } else {
            url.searchParams.set("paginator", "20");
        }
        url.searchParams.set("page", "1");
        const searchEl = this.hasSearchInputTarget ? this.searchInputTarget : document.getElementById("search_term");
        url.searchParams.set("search_term", searchEl ? (searchEl.value ?? "") : "");
        if (window.Turbo) {
            window.Turbo.visit(url.toString(), { frame: "workspace_show_content-members" });
        } else {
            const frame = document.getElementById("workspace_show_content-members");
            if (frame) frame.src = url.toString();
        }
    }
}
