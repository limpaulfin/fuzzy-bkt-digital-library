# Purpose: Create figures for paper (CUD palette)
# Autor: T.H.N. Tran, T.P. Lam, N.M.Q. Nguyen
# Datum: 2026
# Dependencies: ggplot2, jsonlite

library(ggplot2)
library(jsonlite)

# --- Config ---
config <- fromJSON("config/parameters.json")
CUD <- config$cud_palette
log_msg <- function(msg) cat(paste0("[", Sys.time(), "] ", msg, "\n"))

log_msg("Starting 05-visualize.R")
fig_dir <- config$output$figures_dir
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)

# --- Vietnamese font support ---
theme_paper <- theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(size = 13, face = "bold"),
    axis.title = element_text(size = 11),
    legend.position = "bottom",
    legend.title = element_text(size = 10),
    legend.text = element_text(size = 9)
  )

# --- Hình 2: Quỹ đạo kiến thức (BKT nhị phân vs Fuzzy-BKT) ---
traj <- fromJSON("output/fuzzy_trajectory.json")

p2 <- ggplot(traj, aes(x = step)) +
  geom_line(aes(y = p_know_binary, color = "BKT truyền thống"),
            linewidth = 1) +
  geom_line(aes(y = fuzzy_defuzzified, color = "Fuzzy-BKT"),
            linewidth = 1, linetype = "dashed") +
  geom_point(aes(y = correct * 0.02 - 0.01),
             shape = "|", size = 2, color = CUD$black) +
  scale_color_manual(values = c(
    "BKT truyền thống" = CUD$blue,
    "Fuzzy-BKT" = CUD$vermilion
  )) +
  labs(
    title = "Quỹ đạo kiến thức: BKT truyền thống và Fuzzy-BKT",
    x = "Bước tương tác", y = "Xác suất nắm vững P(L)",
    color = "Mô hình"
  ) +
  ylim(0, 1) +
  theme_paper

ggsave(file.path(fig_dir, "fig02-knowledge-trajectory.png"),
       p2, width = config$output$width, height = config$output$height,
       dpi = config$output$dpi)
log_msg("Hình 2 saved")

# --- Hình 3: Phân phối thời gian phản hồi ---
df <- read.csv("../data/as_clean.csv", stringsAsFactors = FALSE)
df_rt <- df[!is.na(df$ms_first_response) &
            df$ms_first_response > 0 &
            df$ms_first_response < 300000, ]

df_rt$log_rt <- log10(df_rt$ms_first_response)
fast_th_log <- log10(config$cognitive_offloading$fast_threshold_ms)

p3 <- ggplot(df_rt, aes(x = log_rt)) +
  geom_histogram(aes(fill = ifelse(log_rt < fast_th_log,
                     "Nghi ngờ (< 3 giây)", "Bình thường")),
                 bins = 50, alpha = 0.8) +
  geom_vline(xintercept = fast_th_log,
             color = CUD$vermilion, linewidth = 1,
             linetype = "dashed") +
  scale_fill_manual(values = c(
    "Nghi ngờ (< 3 giây)" = CUD$vermilion,
    "Bình thường" = CUD$skyblue
  )) +
  annotate("text", x = fast_th_log - 0.3, y = 30000,
           label = "Ngưỡng\n3 giây", color = CUD$vermilion,
           size = 3.5, fontface = "bold") +
  labs(
    title = "Phân phối thời gian phản hồi đầu tiên",
    x = "log10(thời gian phản hồi, ms)",
    y = "Số lượng", fill = "Phân loại"
  ) +
  theme_paper

ggsave(file.path(fig_dir, "fig03-response-time-dist.png"),
       p3, width = config$output$width, height = config$output$height,
       dpi = config$output$dpi)
log_msg("Hình 3 saved")

log_msg("05-visualize.R DONE")
