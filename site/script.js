document.documentElement.classList.add("js");

const stageContent = {
  observe: {
    kicker: "Start with the source",
    title: "See your data before it becomes a finding.",
    copy: "Review the 30-day rhythm, signal coverage, source mix, and privacy-safe records. Gaps stay visible; Vueniverse never fills them with examples.",
    proof: "Exact local counts, coverage, and source freshness",
  },
  discover: {
    kicker: "Look for repetition",
    title: "Find a pattern without forcing one.",
    copy: "Deterministic detectors compare recurring moments with your own matched baseline. A result can be supported, mixed, null, developing, or simply insufficient.",
    proof: "Occurrence count, effect range, completeness, and evidence state",
  },
  replay: {
    kicker: "Return to the moment",
    title: "See how the signal unfolded each time.",
    copy: "Moment Fingerprint overlays repeated traces beside similar no-event windows, so you can inspect timing, recovery, and the shape of the variation, not just one average.",
    proof: "Included traces, matched windows, and recovery duration",
  },
  challenge: {
    kicker: "Try to weaken it",
    title: "Question the evidence before you trust it.",
    copy: "Review meetings that did not match, missing context, possible influences, exclusions, and counterevidence. Correct a detail and the affected result is recalculated.",
    proof: "Contradictions, exclusions, influences, and data gaps",
  },
  explain: {
    kicker: "Make it understandable",
    title: "Get a bounded explanation, grounded in the numbers.",
    copy: "MedGemma can narrate only the verified evidence bundle. Every answer is checked before display, and deterministic wording takes over whenever the model is unavailable or unsafe.",
    proof: "Evidence citations, uncertainty, runtime provenance, and guard result",
  },
  test: {
    kicker: "Choose one small change",
    title: "Predeclare a personal experiment.",
    copy: "Define the change, the outcome, eligibility rules, duration, and confounders before starting. Stop at any time without turning incomplete data into a conclusion.",
    proof: "Planned change, outcome measure, eligibility, and context checks",
  },
  learn: {
    kicker: "Measure what changed",
    title: "Let the result update what you believe.",
    copy: "Compare the planned outcome with the earlier baseline. Vueniverse preserves mixed or incomplete outcomes instead of forcing a success story.",
    proof: "Before-and-after result, protocol adherence, and honest outcome state",
  },
  preserve: {
    kicker: "Keep the history",
    title: "Save the evidence trail, not just the headline.",
    copy: "History keeps versioned findings and experiment results. Proof export includes sources, analysis version, evidence state, runtime provenance, and deletion status.",
    proof: "Versioned evidence, sources, analysis, model, and lifecycle receipts",
  },
};

const tabs = [...document.querySelectorAll("[data-stage]")];
const title = document.querySelector("[data-stage-title]");
const kicker = document.querySelector("[data-stage-kicker]");
const copy = document.querySelector("[data-stage-copy]");
const proof = document.querySelector("[data-stage-proof]");

tabs.forEach((tab) => {
  tab.addEventListener("click", () => {
    const content = stageContent[tab.dataset.stage];
    if (!content) return;

    tabs.forEach((item) => {
      const active = item === tab;
      item.classList.toggle("is-active", active);
      item.setAttribute("aria-selected", String(active));
    });

    kicker.textContent = content.kicker;
    title.textContent = content.title;
    copy.textContent = content.copy;
    proof.textContent = content.proof;
  });
});

const menuButton = document.querySelector("[data-menu-button]");
const menu = document.querySelector("[data-menu]");

menuButton?.addEventListener("click", () => {
  const open = menuButton.getAttribute("aria-expanded") !== "true";
  menuButton.setAttribute("aria-expanded", String(open));
  menu.classList.toggle("is-open", open);
});

menu?.querySelectorAll("a").forEach((link) => {
  link.addEventListener("click", () => {
    menuButton?.setAttribute("aria-expanded", "false");
    menu.classList.remove("is-open");
  });
});

const header = document.querySelector("[data-header]");
const updateHeader = () => header?.classList.toggle("is-scrolled", window.scrollY > 16);
window.addEventListener("scroll", updateHeader, { passive: true });
updateHeader();

const revealItems = document.querySelectorAll("[data-reveal]");
if ("IntersectionObserver" in window) {
  const observer = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (!entry.isIntersecting) return;
        entry.target.classList.add("is-visible");
        observer.unobserve(entry.target);
      });
    },
    { threshold: 0.12 },
  );
  revealItems.forEach((item) => observer.observe(item));
} else {
  revealItems.forEach((item) => item.classList.add("is-visible"));
}
