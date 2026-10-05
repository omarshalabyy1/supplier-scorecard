# 08 · Build checklist

Follow in order. A **Check** line is a number to verify before going on (all from `06-checks.md`); if
it is off, fix that step first.

## Prepare the data (in the repo folder)

1. First time only: copy `.env.example` to `.env`, and put the four order files in `data/input/` (the
   demo's download commands are in `data/input/README.md`). Start Docker Desktop, then:

   ```bash
   docker compose up -d
   ```

2. First time only:

   ```bash
   pip install -r requirements.txt
   ```

3. Load the warehouse:

   ```bash
   python load.py
   ```

   **Check:** it prints `star.fact_order_line 112,650 rows` and ends with `All checks passed.`
4. Start Ollama on the CPU, in its own PowerShell window that stays open. If the Ollama icon is in the
   taskbar tray, right-click it → **Quit Ollama** first. (The CPU setting is needed while the NVIDIA
   driver is older than Ollama expects; with a newer driver, start Ollama normally.)

   ```powershell
   $env:CUDA_VISIBLE_DEVICES = "-1"; $env:GGML_VK_VISIBLE_DEVICES = "-1"; ollama serve
   ```

5. First time only, in another window (2.0 GB):

   ```bash
   ollama pull llama3.2:3b
   ```

6. Write the weekly summaries for `summary.week` in `config/client.yaml` (about three minutes). `load.py`
   empties them, so run this after every load:

   ```bash
   python summarize.py
   ```

   **Check:** 11 lines, the first starting `All departments:` with 2035 order lines, a late rate of 2.5%,
   down from 6.6% last week, and 96.4% on time and in full. The wording changes from run to run; the
   numbers do not.

## Set up Power BI Desktop

7. Open Power BI Desktop → **Blank report**.
8. **File → Options and settings → Options → Current file:**
   - **Data load:** untick **Auto date/time**.
   - **Report settings:** tick **Change default visual interaction from cross highlighting to cross filtering**.
9. **View → Themes → Browse for themes** → `powerbi/05-theme.json`.

## Power Query (`01-power-query.md`)

10. **Home → Transform data.** Create `Warehouse` (connect with `warehouse.user` and `DB_PASSWORD`, demo
    `scorecard` and `scorecard`, without encryption if asked) and untick its **Enable load**.
11. Create the seven queries in this order, pasting each one's M code: `fact_order_line`, `dim_supplier`,
    `dim_product`, `dim_date`, `buyer`, `weekly_summary`, `client_setting`.
12. **Home → Close & Apply.** Then **Home → Enter data**, name it `_Measures`, **Load**.
13. Open **Table view** and click each table; the row count is at the bottom left.
    **Check:** fact_order_line 112,650 · dim_supplier 3,095 · dim_product 32,951 · dim_date 774 ·
    buyer 10 · weekly_summary 11 · client_setting 1.

## Model (`02-model.md`)

14. **Model view:** delete every relationship Power BI made on its own, then create the three in the
    table (Many to one, Single, Active).
15. Mark `dim_date` as the date table (column `date`).
16. Sort `dim_date[month]` by `month_sort`.
17. Set the column formats and summarization from the table in `02-model.md`.
18. Add the calculated columns `Delivery` and `Handover` to `fact_order_line` (top of `03-measures.dax`).
19. Hide the columns and the `buyer` and `client_setting` tables listed under "Hidden columns".

## Measures (`03-measures.dax`)

20. Paste the 19 measures one by one into `_Measures`, each with its format string and display folder.
    Then delete `Column1` from `_Measures`.
21. On a blank page, drop three cards: `[Order Lines]`, `[Late Lines]`, `[Late Rate %]` (Display units: None).
    **Check:** 112,650 · 7,265 · 6.6%. Delete the three cards.

## Security (`02-model.md`)

22. **Modeling → Manage roles:** create the `Buyer` role with its two DAX filters (`dim_product` and
    `weekly_summary`), **Save**.

## Page 1 · Scorecard (`04-pages.md`)

23. Rename the page **Scorecard**. Build visuals 1 to 12 in order, with their positions, fields,
    settings and visual filters.
24. **Check** with nothing selected: Orders 98,666 · Order lines 112,650 · On time, in full 91.4% ·
    Fill rate 97.8% · Late rate 6.6% · Suppliers on the watch list 61.
25. **Check** #11: Health & Beauty 7.3% on top, Kitchen & Appliances 4.9% at the bottom. #10: 18 months,
    highest Mar 2018 at 16.3%. #12: 11 rows.

## Page 2 · Suppliers

26. Add a page, rename it **Suppliers**. Build visuals 1 to 9. (Paste the slicers in step 32.)
27. **Check:** cards 61 · 4.4% · 12.0% · 13.2%. Table first row S0082, MA, 402, 78, 19.4%, 80.0%,
    31.9%, 1.1%, flag. Table total 110,196 delivered, 7,265 late, OTIF 91.5%.

## Page 3 · Why late

28. Add a page, rename it **Why late**. Build visuals 1 to 10.
29. **Check:** cards 7,265 · 29.0% · 9.4% · 10.5. #8: Late hand-over 20.5%, On-time hand-over 5.2%.
    #9: Other 42.9% first, Sports & Fashion 20.0% last.

## Page 4 · Supplier detail

30. Add a page, rename it **Supplier detail**, set it up as a drill-through page on
    `dim_supplier[supplier]` with **Keep all filters** on. Build visuals 2 to 8 (Power BI adds #1, the
    back button). Hide the page.
31. **Check:** on page 2, right-click S0082 in the table → **Drill through → Supplier detail**:
    Delivered lines 402 · Late rate 19.4% · On time, in full 80.0% · Hand-overs that were late 31.9% ·
    table 405 rows. Go back with the back button (Ctrl+click it in Desktop).

## Slicers and interactions (`07-interactions.md`)

32. Copy the two slicers from page 1 to pages 2 and 3 (choose **Sync**). **View → Sync slicers:**
    both synced and visible on Scorecard, Suppliers and Why late only.
33. Set every interaction page by page as in `07-interactions.md`.
34. **Check:** on page 1 click Health & Beauty in #11: Orders 12,013 · Order lines 13,128 ·
    On time, in full 90.7% · Fill rate 97.9% · Late rate 7.3% · Suppliers on the watch list 7. Click
    it again to clear.

## Test the security

35. **Modeling → View as** → **Other user** `buyer.electronics@example.com`, tick **Buyer** → **OK**.
    **Check:** page 1 shows Electronics only: Orders 15,383 · Order lines 17,271 · On time, in full
    91.0% · Fill rate 97.7% · Late rate 6.8% · watch list 7 · one summary row. Page 2 watch-list late
    rate 13.6%. **Stop viewing.**

## Save and screenshots

36. **File → Save as** `powerbi/Supplier_Scorecard.pbix`.
37. With nothing selected and not viewing as a role, take one screenshot per page at 1280 × 720 into
    `powerbi/screenshots/`: `1-scorecard.png`, `2-suppliers.png`, `3-why-late.png`, and page 4 drilled
    to S0082 as `4-supplier-detail.png`.
38. Commit the `.pbix` and the screenshots, and push. A chat then adds the screenshots to the README.
