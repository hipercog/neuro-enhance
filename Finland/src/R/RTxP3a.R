library(haven)
library(tidyverse)
library(ggplot2)
library(ggridges)
library(viridis)
library(hrbrthemes)
library(lme4)
library(emmeans)
library(sjPlot)

path = file.path("~", "Benslab", "METHODMAN", "project_NEUROENHANCE", "Finland", "P3a_flanker_Latency_RT.sav")
dat = read_sav(path)
head(dat)

df <- dat %>% 
  mutate(MEAN_P3a_DEV_LAT = rowMeans(select(., c(2, 4, 5, 6, 7))), .after = 1) %>%
  select(., !(c(2, 4, 5, 6, 7) + 1)) %>%
  rename(Inhibition = "INH_incong_ero_osio1", Switching = "Swi_erot_inh_osiosta") %>%
  rename(Deviant = "MEAN_P3a_DEV_LAT", Novel = "MEAN_P3a_NOV_LAT", ID = "ExcelID") %>%
  pivot_longer(cols = 2:3, names_to = "ERPs", values_to = "P3a") %>%
  pivot_longer(cols = 2:3, names_to = "EFs", values_to = "RTs")
df$EFxERP <- with(df, as.factor(ERPs):as.factor(EFs))

df.all <- dat %>% 
  rename(Inhibition = "INH_incong_ero_osio1", Switching = "Swi_erot_inh_osiosta") %>%
  rename(ID = "ExcelID",
         Interval = "MEAN_P3a_INT_lat", 
         Novel = "MEAN_P3a_NOV_LAT", 
         Duration = "MEAN_P3a_DUR_LAT",
         Gap = "MEAN_P3a_GAP_LAT",
         Location = "MEAN_P3a_LOC_LAT",
         Freq = "MEAN_P3a_FREQ_LAT") %>%
  pivot_longer(cols = 2:7, names_to = "ERPs", values_to = "P3a") %>%
  pivot_longer(cols = 2:3, names_to = "EFs", values_to = "RTs") %>%
  mutate(EFxERP = as.factor(ERPs):as.factor(EFs))

df.all$all_factors <- with(df.all, interaction(ERPs, EFs))

# PLOTTING

ggplot(df, aes(x = RTs, y = P3a, color = EFxERP)) +
  geom_point() + 
  facet_wrap(~ EFxERP) +
  geom_smooth(method = "lm", level = 0.95) +
  labs(x = "RTs (ms)", y = "P3a latency (ms)") +
  theme_classic()

# TESTING

# mu by lmer
p3a_lmer <- lmer(P3a ~ RTs*ERPs + (1|ID), data = filter(df.all, EFs == "Inhibition"))
p3a_lmer <- lmer(P3a ~ RTs*EFs*ERPs + (1|ID), data = df.all)
summary(p3a_lmer, digits = 3)
plot_model(p3a_lmer, type = "diag")[[4]]
joint_tests(p3a_lmer)
joint_tests(p3a_lmer, by = "ERPs")
joint_tests(p3a_lmer, by = "EFs")

###############################################
df <- dat %>%
  pivot_longer(cols = starts_with("MEAN"), names_to = "multifeature", values_to = "P3a_lat") %>%
  mutate(multifeature = gsub("_LAT", "", gsub("MEAN_P3a_", "", multifeature), ignore.case = TRUE)) %>%
  rename(Inhibition = "INH_incong_ero_osio1", Switching = "Swi_erot_inh_osiosta")

# Testing
ggplot(df, aes(x = Inhibition, y = Switching, color = P3a_lat)) +
  geom_point()

ggplot(df, aes(x = P3a_lat, y = Switching, color = Inhibition)) +
  geom_point()

ggplot(df, aes(x = P3a_lat, y = Inhibition, color = Switching)) +
  geom_point()

# Combine EFs
df <- df %>%
  pivot_longer(cols = 2:3, names_to = "EFs", values_to = "RTs")

df$EFxERP <- with(df, as.factor(multifeature):as.factor(EFs))

# Illustrative - doubles up the number of points so only FYI
ggplot(df, aes(x = multifeature, y = P3a_lat, color = RTs, group = EFs)) +
  geom_point(position = position_dodge(0.8))

# Testing
ggplot(df, aes(x = RTs, y = P3a_lat, color = multifeature, group = EFs)) +
  geom_point()

ggplot(df, aes(x = RTs, y = P3a_lat, color = EFxERP)) +
  geom_point() + 
  facet_wrap(~ EFxERP) +
  geom_smooth(method = "lm")


ggplot(df, aes(x = P3a_lat, y = multifeature, size = RTs, color = EFs)) +
  geom_point()

# RIDGES?
ggplot(df, aes(x = P3a_lat, y = multifeature, fill = factor(stat(quantile)))) +
  stat_density_ridges(
    geom = "density_ridges_gradient",
    calc_ecdf = TRUE,
    quantiles = c(0.025, 0.5, 0.975),
    quantile_lines = TRUE
  ) +
  scale_fill_manual(
    name = "Probability", values = c("#666666A0", "#E0E0E0A0", "#E0E0E0A0", "#999999A0"),
    labels = c("(0, 0.025]", "(0.025, 0.5]", "(0.5, 0.975]", "(0.975, 1]")
  ) +
  xlab('P3a latency') +
  ylab('Multifeature condition') +
  theme_ipsum() +
  theme(
    legend.position="none",
    panel.spacing = unit(0.1, "lines"),
    axis.title.x = element_text(size=11),
    axis.title.y= element_text(size=11),
    axis.text.y = element_text(angle = 45, hjust = 1)
  )

ggplot(df, aes(x = P3a_lat, y = multifeature, fill = ..x.., panel)) +
  geom_density_ridges_gradient(scale = 3, rel_min_height = 0.01) +
  scale_fill_viridis(name = "RTs", option = "C") +
  xlab('P3a latency') +
  ylab('Multifeature condition') +
  theme_ipsum() +
  facet_wrap(~ EFs)
