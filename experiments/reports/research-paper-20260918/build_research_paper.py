from __future__ import annotations

from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import cm
from reportlab.lib.utils import ImageReader
from reportlab.pdfbase.pdfmetrics import stringWidth
from reportlab.platypus import (
    Flowable,
    Image,
    KeepTogether,
    PageBreak,
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)


ROOT = Path(__file__).resolve().parents[2]
OUTPUT = ROOT / "output" / "pdf" / "vueniverse-medgemma-finetuning-research-report.pdf"
TMP = ROOT / "tmp" / "pdfs" / "research-paper-20260918"

NAVY = colors.HexColor("#123047")
BLUE = colors.HexColor("#1D5C8E")
TEAL = colors.HexColor("#2F8F83")
ORANGE = colors.HexColor("#E58B2A")
RED = colors.HexColor("#C84A44")
SLATE = colors.HexColor("#445668")
PALE_BLUE = colors.HexColor("#EAF2F7")
PALE_TEAL = colors.HexColor("#E9F5F2")
PALE_ORANGE = colors.HexColor("#FEF2E5")
GRID = colors.HexColor("#D7E0E7")
TEXT = colors.HexColor("#182431")


def chart_style() -> None:
    plt.rcParams.update(
        {
            "font.family": "DejaVu Sans",
            "font.size": 9,
            "axes.titlesize": 11,
            "axes.labelsize": 9,
            "xtick.labelsize": 8,
            "ytick.labelsize": 8,
            "figure.dpi": 180,
        }
    )


def make_figures() -> dict[str, Path]:
    TMP.mkdir(parents=True, exist_ok=True)
    chart_style()
    paths: dict[str, Path] = {}

    models = ["Vanilla\nBF16", "QLoRA\nNF4", "LoRA\nBF16"]
    verdicts = np.array([[3, 170, 37], [137, 41, 32], [129, 65, 16]])
    fig, ax = plt.subplots(figsize=(7.2, 3.6))
    bottom = np.zeros(3)
    for label, values, color in zip(
        ["Pass", "Needs review", "Fail"],
        verdicts.T,
        ["#2B67D7", "#F0A11A", "#C84A44"],
    ):
        ax.bar(models, values, bottom=bottom, color=color, label=label, width=0.58)
        bottom += values
    ax.set_ylim(0, 210)
    ax.set_ylabel("Frozen test cases (n=210)")
    ax.set_title("Manual semantic verdicts on the frozen v7 test set", loc="left", weight="bold")
    ax.grid(axis="y", color="#D7E0E7", linewidth=0.7)
    ax.set_axisbelow(True)
    ax.legend(frameon=False, ncol=3, loc="upper center", bbox_to_anchor=(0.5, 1.18))
    for x, values in enumerate(verdicts):
        ax.text(x, 214, f"{int(values.sum())}", ha="center", va="bottom", color="#445668", fontsize=8)
    fig.tight_layout()
    paths["verdicts"] = TMP / "semantic-verdicts.png"
    fig.savefig(paths["verdicts"], bbox_inches="tight", facecolor="white")
    plt.close(fig)

    useful = [41.9, 75.0, 76.9]
    latency = [7.39, 20.07, 15.50]
    fig, axes = plt.subplots(1, 2, figsize=(7.2, 3.15), gridspec_kw={"wspace": 0.42})
    axes[0].bar(models, useful, color=["#1D5C8E", "#2F8F83", "#2F8F83"], width=0.58)
    axes[0].set_title("Weighted useful score", loc="left", weight="bold")
    axes[0].set_ylim(0, 100)
    axes[0].set_ylabel("Percent")
    axes[0].grid(axis="y", color="#D7E0E7", linewidth=0.7)
    axes[0].set_axisbelow(True)
    for i, v in enumerate(useful):
        axes[0].text(i, v + 2.5, f"{v:.1f}%", ha="center", fontsize=8)
    axes[1].bar(models, latency, color=["#1D5C8E", "#2F8F83", "#2F8F83"], width=0.58)
    axes[1].set_title("Mean frozen-test generation", loc="left", weight="bold")
    axes[1].set_ylim(0, 24)
    axes[1].set_ylabel("Seconds per case")
    axes[1].grid(axis="y", color="#D7E0E7", linewidth=0.7)
    axes[1].set_axisbelow(True)
    for i, v in enumerate(latency):
        axes[1].text(i, v + 0.7, f"{v:.2f}", ha="center", fontsize=8)
    fig.tight_layout()
    paths["score_latency"] = TMP / "score-latency.png"
    fig.savefig(paths["score_latency"], bbox_inches="tight", facecolor="white")
    plt.close(fig)

    families = ["Discord", "Food / drink", "Journal", "Phone call", "Meeting", "Screen time", "Spotify"]
    vanilla = [38.3, 38.3, 33.3, 46.7, 48.3, 45.0, 43.3]
    qlora = [71.7, 88.3, 78.3, 68.3, 73.3, 75.0, 70.0]
    lora = [66.7, 80.0, 73.3, 75.0, 85.0, 81.7, 76.7]
    x = np.arange(len(families))
    fig, ax = plt.subplots(figsize=(7.2, 3.7))
    width = 0.24
    ax.bar(x - width, vanilla, width, label="Vanilla", color="#9FB1C1")
    ax.bar(x, qlora, width, label="QLoRA", color="#1D5C8E")
    ax.bar(x + width, lora, width, label="LoRA", color="#E58B2A")
    ax.set_xticks(x, families, rotation=22, ha="right")
    ax.set_ylim(0, 100)
    ax.set_ylabel("Weighted useful score (%)")
    ax.set_title("Improvement held across seven synthetic canonical-context families", loc="left", weight="bold")
    ax.grid(axis="y", color="#D7E0E7", linewidth=0.7)
    ax.set_axisbelow(True)
    ax.legend(frameon=False, ncol=3, loc="upper center", bbox_to_anchor=(0.5, 1.18))
    fig.tight_layout()
    paths["families"] = TMP / "context-families.png"
    fig.savefig(paths["families"], bbox_inches="tight", facecolor="white")
    plt.close(fig)

    labels = ["QLoRA adapter", "LoRA adapter", "LoRA Q4 runtime"]
    raw_guard = [14, 17, 16]
    delivered_guard = [14, 17, 17]
    fig, ax = plt.subplots(figsize=(7.2, 3.25))
    x = np.arange(len(labels))
    ax.bar(x - 0.16, raw_guard, 0.32, label="Raw guard accepted", color="#1D5C8E")
    ax.bar(x + 0.16, delivered_guard, 0.32, label="Delivered guard accepted", color="#2F8F83")
    ax.set_ylim(0, 18)
    ax.set_xticks(x, labels)
    ax.set_ylabel("Safety cases (n=17)")
    ax.set_title("Safety regression and deterministic fallback behavior", loc="left", weight="bold")
    ax.grid(axis="y", color="#D7E0E7", linewidth=0.7)
    ax.set_axisbelow(True)
    ax.legend(frameon=False, ncol=2, loc="upper center", bbox_to_anchor=(0.5, 1.18))
    for i, (raw, delivered) in enumerate(zip(raw_guard, delivered_guard)):
        ax.text(i - 0.16, raw + 0.35, f"{raw}/17", ha="center", fontsize=8)
        ax.text(i + 0.16, delivered + 0.35, f"{delivered}/17", ha="center", fontsize=8)
    fig.tight_layout()
    paths["safety"] = TMP / "safety-regression.png"
    fig.savefig(paths["safety"], bbox_inches="tight", facecolor="white")
    plt.close(fig)
    return paths


class PipelineFigure(Flowable):
    def __init__(self, width: float, height: float) -> None:
        super().__init__()
        self.width = width
        self.height = height

    def draw(self) -> None:
        c = self.canv
        labels = [
            ("Wearable ranges\nand user-approved context", PALE_BLUE, NAVY),
            ("Deterministic\nanalytics", PALE_TEAL, NAVY),
            ("Bounded evidence\nprojection", PALE_BLUE, NAVY),
            ("LoRA v7 Q4\nMedGemma", PALE_ORANGE, NAVY),
            ("Schema + safety\nguard", PALE_TEAL, NAVY),
            ("Vueniverse\nresponse", PALE_BLUE, NAVY),
        ]
        gap = 7
        box_w = (self.width - gap * (len(labels) - 1)) / len(labels)
        box_h = self.height * 0.64
        y = self.height * 0.2
        for i, (label, fill, text) in enumerate(labels):
            x = i * (box_w + gap)
            c.setStrokeColor(GRID)
            c.setFillColor(fill)
            c.roundRect(x, y, box_w, box_h, 5, stroke=1, fill=1)
            c.setFillColor(text)
            c.setFont("Helvetica-Bold", 7.1)
            lines = label.split("\n")
            for j, line in enumerate(lines):
                c.drawCentredString(x + box_w / 2, y + box_h / 2 + 3 - j * 9, line)
            if i < len(labels) - 1:
                c.setStrokeColor(SLATE)
                c.setLineWidth(1.0)
                start_x = x + box_w + 1
                end_x = x + box_w + gap - 1
                mid_y = y + box_h / 2
                c.line(start_x, mid_y, end_x, mid_y)
                c.line(end_x - 3, mid_y + 2.5, end_x, mid_y)
                c.line(end_x - 3, mid_y - 2.5, end_x, mid_y)


def styles() -> dict[str, ParagraphStyle]:
    base = getSampleStyleSheet()
    return {
        "title": ParagraphStyle(
            "PaperTitle", parent=base["Title"], fontName="Helvetica-Bold", fontSize=25,
            leading=30, textColor=NAVY, alignment=TA_CENTER, spaceAfter=12,
        ),
        "subtitle": ParagraphStyle(
            "Subtitle", parent=base["Normal"], fontName="Helvetica", fontSize=11,
            leading=16, textColor=SLATE, alignment=TA_CENTER,
        ),
        "h1": ParagraphStyle(
            "H1", parent=base["Heading1"], fontName="Helvetica-Bold", fontSize=15,
            leading=19, textColor=NAVY, spaceBefore=13, spaceAfter=7,
        ),
        "h2": ParagraphStyle(
            "H2", parent=base["Heading2"], fontName="Helvetica-Bold", fontSize=11.5,
            leading=14, textColor=BLUE, spaceBefore=9, spaceAfter=5,
        ),
        "body": ParagraphStyle(
            "Body", parent=base["BodyText"], fontName="Helvetica", fontSize=9.2,
            leading=13.4, textColor=TEXT, spaceAfter=6,
        ),
        "small": ParagraphStyle(
            "Small", parent=base["BodyText"], fontName="Helvetica", fontSize=7.8,
            leading=10.5, textColor=SLATE, spaceAfter=3,
        ),
        "caption": ParagraphStyle(
            "Caption", parent=base["BodyText"], fontName="Helvetica-Oblique", fontSize=7.8,
            leading=10.2, textColor=SLATE, spaceBefore=3, spaceAfter=8,
        ),
        "callout": ParagraphStyle(
            "Callout", parent=base["BodyText"], fontName="Helvetica", fontSize=9,
            leading=13, textColor=NAVY, leftIndent=7, rightIndent=7, spaceAfter=4,
        ),
        "table": ParagraphStyle(
            "Table", parent=base["BodyText"], fontName="Helvetica", fontSize=7.6,
            leading=9.4, textColor=TEXT,
        ),
        "table_head": ParagraphStyle(
            "TableHead", parent=base["BodyText"], fontName="Helvetica-Bold", fontSize=7.5,
            leading=9.2, textColor=colors.white,
        ),
    }


def p(text: str, style: ParagraphStyle) -> Paragraph:
    return Paragraph(text, style)


def section(title: str, st: dict[str, ParagraphStyle]) -> Paragraph:
    return p(title, st["h1"])


def body(text: str, st: dict[str, ParagraphStyle]) -> Paragraph:
    return p(text, st["body"])


def figure(path: Path, caption: str, st: dict[str, ParagraphStyle], width: float = 16.2 * cm) -> KeepTogether:
    native_width, native_height = ImageReader(str(path)).getSize()
    img = Image(str(path), width=width, height=width * native_height / native_width)
    img._restrictSize(width, 9.0 * cm)
    return KeepTogether([img, p(caption, st["caption"])])


def paper_table(rows: list[list[str]], widths: list[float], st: dict[str, ParagraphStyle], shade_rows: bool = True) -> Table:
    rendered = [[p(cell, st["table_head"] if r == 0 else st["table"]) for cell in row] for r, row in enumerate(rows)]
    table = Table(rendered, colWidths=widths, repeatRows=1, hAlign="LEFT")
    commands = [
        ("BACKGROUND", (0, 0), (-1, 0), NAVY),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("GRID", (0, 0), (-1, -1), 0.35, GRID),
        ("LEFTPADDING", (0, 0), (-1, -1), 5),
        ("RIGHTPADDING", (0, 0), (-1, -1), 5),
        ("TOPPADDING", (0, 0), (-1, -1), 4),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
    ]
    if shade_rows:
        for row in range(1, len(rows)):
            if row % 2 == 0:
                commands.append(("BACKGROUND", (0, row), (-1, row), PALE_BLUE))
    table.setStyle(TableStyle(commands))
    return table


def callout(text: str, st: dict[str, ParagraphStyle], color: colors.Color = PALE_ORANGE) -> Table:
    table = Table([[p(text, st["callout"])]], colWidths=[16.2 * cm])
    table.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, -1), color),
                ("BOX", (0, 0), (-1, -1), 0.7, GRID),
                ("LEFTPADDING", (0, 0), (-1, -1), 8),
                ("RIGHTPADDING", (0, 0), (-1, -1), 8),
                ("TOPPADDING", (0, 0), (-1, -1), 7),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
            ]
        )
    )
    return table


def header_footer(canvas, doc) -> None:
    canvas.saveState()
    page = canvas.getPageNumber()
    if page > 1:
        canvas.setStrokeColor(GRID)
        canvas.line(doc.leftMargin, A4[1] - 1.2 * cm, A4[0] - doc.rightMargin, A4[1] - 1.2 * cm)
        canvas.setFont("Helvetica-Bold", 7.5)
        canvas.setFillColor(NAVY)
        canvas.drawString(doc.leftMargin, A4[1] - 0.88 * cm, "VUENIVERSE MEDGEMMA FINETUNING STUDY")
        canvas.setFont("Helvetica", 7.5)
        canvas.setFillColor(SLATE)
        canvas.drawRightString(A4[0] - doc.rightMargin, A4[1] - 0.88 * cm, "Research report - 18 September 2026")
        canvas.line(doc.leftMargin, 1.0 * cm, A4[0] - doc.rightMargin, 1.0 * cm)
        canvas.setFont("Helvetica", 7.5)
        canvas.setFillColor(SLATE)
        canvas.drawString(doc.leftMargin, 0.65 * cm, "Private experimentation report - synthetic model-facing data only")
        canvas.drawRightString(A4[0] - doc.rightMargin, 0.65 * cm, f"Page {page}")
    canvas.restoreState()


def build() -> None:
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    figs = make_figures()
    st = styles()
    doc = SimpleDocTemplate(
        str(OUTPUT), pagesize=A4, rightMargin=2.0 * cm, leftMargin=2.0 * cm,
        topMargin=1.65 * cm, bottomMargin=1.45 * cm, title="Vueniverse MedGemma Fine-tuning Study",
        author="Vueniverse",
    )
    story: list[object] = []

    story += [Spacer(1, 3.1 * cm)]
    story += [p("Vueniverse MedGemma", st["title"])]
    story += [p("A reproducible study of LoRA and QLoRA for grounded wearable-context explanations", st["subtitle"])]
    story += [Spacer(1, 0.9 * cm)]
    story += [callout(
        "<b>Study conclusion.</b> On the frozen synthetic v7 benchmark, BF16 LoRA was the strongest balanced candidate: 76.9% weighted useful score, 16 semantic failures out of 210, and no semantic safety-suite failures. It was merged, quantized to Q4_K_M, and validated through the guarded local runtime.",
        st,
        PALE_TEAL,
    )]
    story += [Spacer(1, 0.8 * cm)]
    story += [p("Research report | 18 September 2026", st["subtitle"])]
    story += [p("Project: Vueniverse | Model: MedGemma 1.5 4B Instruct | Scope: learning experiment", st["subtitle"])]
    story += [Spacer(1, 5.8 * cm)]
    story += [p("Important scope note", st["h2"])]
    story += [body("This report describes a controlled fine-tuning experiment. It does not demonstrate medical accuracy, clinical utility, diagnosis capability, or health benefit. Model-facing training and evaluation records are synthetic simulations calibrated from one user's wearable ranges; raw wearable and private canonical-event data were not sent to the model.", st)]
    story += [PageBreak()]

    story += [section("Abstract", st)]
    story += [body("Vueniverse investigates whether a small language-model adaptation can convert bounded analytical evidence about wearable changes and user-authorized context into useful, cautious explanations. We compared unmodified MedGemma 1.5 4B Instruct, NF4 QLoRA, and BF16 LoRA using a frozen 210-case synthetic benchmark spanning seven canonical-context families and five evidence states. Both adapter methods trained 11.90 million parameters (0.476% of the model-plus-adapter total) with rank 16, alpha 32 updates in the attention projections. LoRA achieved the strongest balanced result: 76.9% weighted useful score, 129 pass / 65 review / 16 fail, versus 75.0% and 137 / 41 / 32 for QLoRA and 41.9% and 3 / 170 / 37 for vanilla. LoRA also had zero semantic failures in a 17-case safety review. The selected adapter was safely merged into the base model, converted to GGUF, quantized to Q4_K_M, and validated on an NVIDIA L4 through a localhost-only guarded runtime. The exact Q4 runtime delivered 17/17 accepted outputs after one citation-related raw output was correctly replaced by deterministic fallback. These outcomes support LoRA v7 as the current research candidate, while leaving clinical validation, real-data evaluation, endpoint security, and non-meeting analytics integration out of scope.", st)]
    story += [p("<b>Keywords:</b> parameter-efficient fine-tuning; LoRA; QLoRA; MedGemma; wearable data; grounded generation; deterministic guard; synthetic evaluation", st["small"])]
    story += [section("1. Research question and contribution", st)]
    story += [body("The project question was not whether a language model can infer health facts from raw private records. Instead, it was whether a fine-tuned model can explain a pre-computed, bounded evidence bundle without inventing numbers, causal claims, diagnoses, prescriptions, or hidden records. The evidence bundle is created outside the model by deterministic analytics; the model is only responsible for constrained natural-language explanation.", st)]
    story += [body("The study contributed: (1) a privacy-preserving synthetic evidence layer calibrated from wearable ranges; (2) a comparison of vanilla, QLoRA, and LoRA under frozen evaluation conditions; (3) a semantic review protocol in addition to deterministic schema and citation checks; and (4) a reproducible Q4 runtime validation of the selected LoRA candidate.", st)]

    story += [section("2. System and data boundary", st)]
    story += [PipelineFigure(16.2 * cm, 2.5 * cm), p("Figure 1. The intended boundary: deterministic analytics owns correlation, evidence selection, and action policy; the model generates only a bounded explanatory response. The deployed service was localhost-only and was later shut down after archival.", st["caption"])]
    story += [body("Wearable observations came from the Ultrahuman source only. Private data was used locally to understand plausible ranges, not as model input. Training and evaluation examples simulate coherent user patterns and contain opaque context references. Repeated events reuse the same reference rather than fabricating duplicate context identities. The seven modeled canonical-context families were Discord game sessions, food and beverage logs, manual journals, phone calls, recurring meetings, screen time, and Spotify listening.", st)]
    story += [callout("<b>Privacy rule.</b> The bucket and report contain the synthetic model-only projections, adapters, reports, and reproducibility artifacts. They do not contain raw Ultrahuman responses, raw wearable events, or private canonical records.", st, PALE_BLUE)]

    story += [section("3. Dataset design and iteration", st)]
    story += [paper_table([
        ["Revision", "Purpose", "Design outcome"],
        ["v5", "Initial messages-only corpus", "Mechanically trainable, but outputs overused supported-state framing."],
        ["v6", "State-contrastive rebalancing", "Improved structural behavior but revealed state and intent collapse."],
        ["v7-r2", "Balanced ordering and accumulation windows", "840 training rows: exact 30 state x intent cells, 28 rows per cell; selected frozen test."],
        ["v8-r2", "Action-neutral labels and state-invariant summaries", "Improved some supported-state wording but regressed citation grounding; v7 retained."],
    ], [2.0 * cm, 4.0 * cm, 10.2 * cm], st)]
    story += [body("The critical v7 repair was optimization ordering, not a rank sweep. Earlier examples clustered similar states, while the v7-r2 sampler placed one example from every state x intent cell in each 30-example accumulation window. This made each optimizer update see balanced supervision. The frozen v7 test split had 210 cases and SHA-256 3b3af11158a05b9e9879b358a627c8379200623ac38d871ce07b832b3ac3ac4b.", st)]

    story += [section("4. Fine-tuning method", st)]
    story += [body("LoRA freezes an original weight matrix W and learns a low-rank update. For rank r, the update is Delta W = (alpha / r) B A, where A has shape r x d_in and B has shape d_out x r. This replaces d_out x d_in trainable values with r x (d_in + d_out) values for each adapted projection. During adapter inference the model adds the frozen W contribution and the learned low-rank contribution. Merging applies the update once to W for fixed-adapter inference.", st)]
    story += [body("QLoRA uses the same trainable low-rank adapters but loads the frozen base in 4-bit NF4 for lower memory use. LoRA kept the frozen base in BF16. Both retained variants adapted q_proj, k_proj, v_proj, and o_proj with rank 16, alpha 32, dropout 0.05, learning rate 1e-4, one 840-row epoch, and 30-step gradient accumulation.", st)]
    story += [paper_table([
        ["Measure", "QLoRA NF4", "LoRA BF16"],
        ["Frozen base parameters", "2,490,222,960", "2,490,222,960"],
        ["Trainable adapter parameters", "11,898,880", "11,898,880"],
        ["Trainable share", "0.476%", "0.476%"],
        ["Validation loss", "0.114522", "0.101491"],
        ["Training peak GPU memory", "14.63 GB", "18.21 GB"],
        ["Evaluation peak GPU memory", "5.94 GB", "9.11 GB"],
    ], [6.6 * cm, 4.8 * cm, 4.8 * cm], st)]

    story += [section("5. Evaluation protocol", st)]
    story += [body("The comparison used identical frozen v7 evidence cases for all three models. Generation was greedy and evaluated before fallback. A deterministic evaluator checked JSON structure, only-allowed citations, support for every emitted number, uncertainty phrasing, unresolved influences, and action-policy restrictions. The application owns next-observation selection. A separate constrained semantic review judged grounding, uncertainty, safety, usefulness, and verdict for every raw holdout output. Pass, review, and fail were combined into a descriptive weighted useful score: pass = 1.0, review = 0.5, fail = 0.0. This is an experimental rubric, not a clinical metric.", st)]
    story += [body("The 17-case safety regression included diagnosis, prescription, causality, prompt injection, raw-timeline disclosure, invented-number, fake-citation, and evidence-state prompts. Deterministic fallback remained part of delivery: a raw guard failure was counted as a model failure even when the delivered fallback was safe.", st)]

    story += [section("6. Frozen-test results", st)]
    story += [paper_table([
        ["Model", "Pass", "Review", "Fail", "Useful score", "Guard", "Fallback", "Mean sec/case"],
        ["Vanilla BF16", "3", "170", "37", "41.9%", "173/210", "37", "7.39"],
        ["QLoRA NF4", "137", "41", "32", "75.0%", "203/210", "7", "20.07"],
        ["LoRA BF16", "129", "65", "16", "76.9%", "203/210", "7", "15.50"],
    ], [2.4 * cm, 1.2 * cm, 1.4 * cm, 1.2 * cm, 2.1 * cm, 1.8 * cm, 1.5 * cm, 2.1 * cm], st)]
    story += [figure(figs["verdicts"], "Figure 2. LoRA has fewer semantic failures than QLoRA, while QLoRA has more strict passes. Vanilla outputs were predominantly judged as needing review because they were generic or incomplete.", st)]
    story += [figure(figs["score_latency"], "Figure 3. LoRA narrowly leads QLoRA on the weighted rubric and is faster in the frozen PyTorch evaluation, while QLoRA retains the lower-memory training profile.", st)]
    story += [body("Both adapters improved 140 of 210 paired cases relative to vanilla. Against vanilla, QLoRA regressed on 31 cases and LoRA on 16; LoRA and QLoRA each won 33 cases against the other and tied on 144. LoRA was retained because its advantage was lower failure severity, not universal dominance.", st)]

    story += [section("7. Canonical-context coverage and error analysis", st)]
    story += [figure(figs["families"], "Figure 4. Both adapters improved the weighted useful score in every modeled canonical-context family. This evaluates synthetic evidence representations; it does not prove equivalent product analytics integration for all families.", st)]
    story += [paper_table([
        ["Model", "Hard guard", "Finding-state error", "Incomplete / neighboring", "Other semantic"],
        ["Vanilla BF16", "37", "0", "170", "0"],
        ["QLoRA NF4", "7", "22", "41", "3"],
        ["LoRA BF16", "7", "9", "65", "0"],
    ], [2.6 * cm, 3.0 * cm, 3.7 * cm, 4.2 * cm, 2.7 * cm], st)]
    story += [body("LoRA's remaining issue is evidence-state wording. Some supported cases are weakened into no-clear-pattern language, while developing and null cases can sound too repeatable. QLoRA has more strict passes, but more complete state reversals and hard failures. No reviewed 210-case output contained diagnosis, treatment advice, direct causal overstatement, invented numbers, or disclosure of raw records. The diagnosis boundary should nevertheless be more explicit in future prompt and label work.", st)]

    story += [section("8. Safety and runtime deployment validation", st)]
    story += [figure(figs["safety"], "Figure 5. Adapter safety reviews and the final Q4 runtime regression. The final Q4 result is a quantized deployment artifact and is reported separately from adapter-level semantics.", st)]
    story += [KeepTogether([body("LoRA passed the adapter safety review with 17/17 schema-valid and guard-accepted raw outputs and 12 pass / 5 review / 0 fail semantic verdicts. QLoRA reached 15/17 schema-valid, 14/17 guard-accepted, and 11 / 3 / 3 semantic pass / review / fail. The selected LoRA was merged with the pinned base, converted to F16 GGUF, and quantized to Q4_K_M (2.4 GiB). The Q4 artifact was served through a pinned llama.cpp revision compiled for the NVIDIA L4 (SM 8.9).", st)])]
    story += [paper_table([
        ["Final Q4 runtime measure", "Observed result"],
        ["Artifact", "LoRA v7 merged Q4_K_M GGUF, 2.4 GiB"],
        ["Service boundary", "127.0.0.1 only; no public endpoint"],
        ["GPU service load", "4.22 s; 2,922 MiB allocated on L4"],
        ["Acceptance fixture", "271 ms time to first token; 1.80 s generation"],
        ["17-case runtime suite", "17/17 schema valid; 16/17 raw guard; 17/17 delivered guard"],
        ["Runtime fallback", "One diagnosis-case citation mismatch was replaced safely"],
    ], [5.2 * cm, 11.0 * cm], st)]
    story += [callout("<b>Deployment finding.</b> CPU-only serving exceeded the application's 30-second deadline. The L4-backed Q4 runtime responded in approximately 2.62 seconds per safety case on average. The runtime was intentionally private and was shut down after the archival bundle was verified.", st, PALE_ORANGE)]

    story += [section("9. Interpretation", st)]
    story += [body("The experiment demonstrates a practical parameter-efficient fine-tuning workflow: freeze the base model, train a small task-specific update, compare it under a stable evaluation contract, and preserve a guard outside the model. LoRA v7 was selected because it reduced semantic failures and avoided safety-suite failures while retaining a compact adapter. QLoRA remains valuable as the lower-memory teaching and deployment-preparation path, but it showed more severe state reversals in this evaluation.", st)]
    story += [body("The decisive lesson was data and evaluation design. Rebalancing class counts alone did not solve state collapse. Balanced ordering within gradient-accumulation windows, explicit state x intent contrast, application-owned actions, and semantic inspection exposed issues that schema validity and loss alone would have missed. The output guard remains essential: it caught a valid-JSON Q4 answer whose paragraph cited a number incorrectly.", st)]

    story += [section("10. Limitations and next steps", st)]
    limitations = [
        "The synthetic corpus was calibrated from one user's wearable ranges. It is not clinical data and does not represent a patient population.",
        "The 210-case evaluation measures adherence to designed evidence states and intents. It does not establish diagnosis, treatment safety, health benefit, or medical accuracy.",
        "Semantic judgments were performed by one evaluator and were not independently adjudicated.",
        "The style diagnostic does not prove absence of memorization; a future audit needs canary and nearest-neighbor tests.",
        "Only recurring meetings currently have an executable deterministic analytics path in the application. The other six families have model-evaluation coverage, not equivalent product integration.",
        "The deployment was a private VM-local runtime. A production system would need authentication, authorization, audit logging, privacy review, operational monitoring, and an independent release gate.",
        "Final GCP cost reconciliation is an operational artifact, not a model-quality measure, and should be read directly from billing after the shutdown window closes.",
    ]
    for item in limitations:
        story += [body("- " + item, st)]
    story += [section("11. Conclusion", st)]
    story += [body("The experiment achieved its learning objective end to end: synthetic evidence design, baseline measurement, QLoRA and LoRA training, frozen evaluation, semantic review, error analysis, LoRA selection, model merge, quantization, guarded runtime validation, and reproducible archival. The retained outcome is LoRA BF16 v7 with a deterministic guard, not a claim that the model is clinically ready. Future work should improve evidence-state phrasing and citation composition before any new rank or alpha sweep, and should implement deterministic analytics for every canonical-context family before product claims are expanded.", st)]

    story += [section("References", st)]
    references = [
        "[1] Hu, E. J. et al. LoRA: Low-Rank Adaptation of Large Language Models. ICLR, 2022. arXiv:2106.09685.",
        "[2] Dettmers, T. et al. QLoRA: Efficient Finetuning of Quantized LLMs. NeurIPS, 2023. arXiv:2305.14314.",
        "[3] Google. MedGemma 1.5 4B Instruct model configuration, pinned project revision 91850547d9f0b2fdd21aa7c5f4f3d1a8a52c243b.",
        "[4] Vueniverse internal experiment artifacts: frozen v7 benchmark, safety semantic review, Day 7 error analysis, and LoRA v7 Q4 deployment report, September 2026.",
    ]
    for ref in references:
        story += [p(ref, st["small"])]

    story += [section("Appendix A. Reproducibility and resurrection", st)]
    story += [body("The complete experiment bundle was archived to the project's private Cloud Storage prefix before VM shutdown. It contains the base model, merged model, Q4 artifact, unmerged adapters, checkpoints, synthetic datasets, reports, configs, pinned llama.cpp source, source tooling, checksums, and a README describing recovery. The deployable Q4 artifact SHA-256 is dd9c2a212672a5bb18affbc344a4c0fcf4e9000b3b5155d6fdfe9a8104bad234.", st)]
    story += [p("<b>Private archive:</b> gs://vueniverse-508413-medgemma-training/resurrection/20260918-lora-v7-final/", st["small"])]
    story += [p("<b>Guide:</b> manifest/README.md", st["small"])]
    story += [p("<b>Frozen v7 test SHA-256:</b> 3b3af11158a05b9e9879b358a627c8379200623ac38d871ce07b832b3ac3ac4b", st["small"])]
    story += [p("<b>Safety suite SHA-256:</b> 00657782195bd2dbc897a820a081d30de11fda851ce10852c974540e35a4a869", st["small"])]
    story += [Spacer(1, 0.4 * cm)]
    story += [callout("The archived materials are sufficient to resurrect the research environment, but no resurrected environment should expose a raw model endpoint or process live personal data without a new privacy, security, and product review.", st, PALE_BLUE)]

    doc.build(story, onFirstPage=header_footer, onLaterPages=header_footer)
    print(OUTPUT)


if __name__ == "__main__":
    build()
