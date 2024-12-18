##load libraries
library(dplyr)
library(stringr)
library(visNetwork)
library(igraph)
library(RColorBrewer)
library(tidyr)
data2 <- read.csv("../data/persondata.csv", quote = "", row.names = NULL, stringsAsFactors = FALSE)
data <- read.csv("../data/relationshipdata.csv", quote = "", row.names = NULL, stringsAsFactors = FALSE)
data <- data %>%
  left_join(data2, by = c("source" = "Chinese")) %>%
  mutate(pinyinsource = ifelse(!is.na(pinyin), pinyin, source))
data <- data %>%
  left_join(data2 %>% 
              rename(pinyin_target = pinyin), by = c("target" = "Chinese")) %>%
  mutate(pinyintarget = ifelse(!is.na(pinyin_target), pinyin_target, target))
data <- data %>% 
  select(-source, -target, -pinyin, -pinyin_target)
data <- data %>%
  mutate(pinyinsource = case_when(
    pinyinsource == "林志义" ~ "Lin Zhiyi",
    pinyinsource == "林天尧" ~ "Lin Tianyao",
    pinyinsource == "洪锦绰" ~ "Hong Jinchuo",
    TRUE ~ pinyinsource
  ))
data <- data %>%
  mutate(pinyintarget = case_when(
    pinyintarget == "转道法师／老和尚" ~ "Zhuandao Fashi/Laoheshang",
    pinyintarget == "张乞" ~ "Zhang Qi",
    pinyintarget == "珊顿•汤姆士" ~ "Shandun Tangmushi",
    pinyintarget == "黄树芳" ~ "Huang Shufang", 
    pinyintarget == "陈季骗" ~ "Chen Jipian",
    pinyintarget == "曾金福" ~ "Zeng Jinfu",
    TRUE ~ pinyintarget
  ))
nodes <- data.frame(unique(c(data$pinyinsource, data$pinyintarget)))
colnames(nodes) <- c("id")
nodes <- nodes %>% mutate(label = nodes$id) %>% distinct(id,label)
nodes$id <- nodes$label
edges <- data %>% select(pinyinsource, pinyintarget, relclas)
colnames(edges) <- c("from","to","label")
edges <- edges %>% mutate(color = label)
edges <- edges %>% mutate(color = str_replace_all(color, c("三代以内直系血亲及夫妻"= "darkred", "普通伙伴" = "lightgreen","普通亲戚" = "pink","轻度社交" = "darkgray","密切伙伴"="darkgreen")))
edges <- edges %>% select(-label)
visNetwork(nodes, edges, main = 'Singapore Chinese Personalities Database Social Network') %>%  
          visPhysics(stabilization = TRUE) %>% 
  visOptions(highlightNearest=TRUE,
             nodesIdSelection=TRUE) %>% 
  visLegend(
    enabled = TRUE,
    addEdges = data.frame(
      label = c("Blood related and couple", "Close friend","relative","friend", "acquaintance"),
      color = c("darkred", "darkgreen", "pink", "lightgreen","darkgray")))%>% 
  visNodes(size = 5, color = list(highlight = "yellow"))



g <- graph_from_data_frame(d=edges, vertices=nodes, directed=FALSE)
g
degree_centrality <- degree(g)
nodes2 <- nodes

nodes2$degree_centrality <- degree_centrality[as.character(nodes2$id)]
head(sort(degree_centrality, decreasing=TRUE))

base_palette <- brewer.pal(9, "YlOrRd")
colors_centrality <- rev(colorRampPalette(base_palette)(705))

importance <- strength(g)
nodes2$importance <- importance

nodes2 <- nodes2 %>% mutate(degree_rank=706-floor(rank(degree_centrality)), color.background=colors_centrality[degree_rank], size=log((importance+3)^5))

visNetwork(nodes2, edges, main = 'Degree Centrality of Prominent Singapore Chinese Personalities') %>%
  visOptions(highlightNearest=TRUE,
             nodesIdSelection=TRUE, selectedBy="degree_rank") %>% 
  visPhysics(stabilization = TRUE) %>% 
  visLegend(
    enabled = TRUE,
    addEdges = data.frame(
      label = c("Blood related and couple", "Close friend","relative","friend", "acquaintance"),
      color = c("darkred", "darkgreen", "pink", "lightgreen","darkgray")))%>% 
  visNodes(color = list(highlight = "yellow"))


#DataVisualization3: Looking at the top 10 personalities who have the greatest number of relationships and see if and what kind of relationships they have with each other. I am counting the occurrence of personality names in both from and to columns in the edges dataframe. 
# Usage of the function pivot_longer helps me combine from and to columns and count them at the same time. 

top_nodes <- edges %>%
  select(from, to) %>%                  
  pivot_longer(cols = everything(),     
               values_to = "name",
               names_to = NULL, 
               names_repair = "minimal") %>% 
  count(name, sort = TRUE) %>% 
  slice_max(n = 20, order_by = n)

filtered_nodes <- nodes %>%  filter(id %in% top_nodes$name|label %in% top_nodes$name)
filtered_edges <- edges %>%  filter(from %in% top_nodes$name|to %in% top_nodes$name)

visNetwork(filtered_nodes, filtered_edges, main = 'Top 20 Singapore Chinese Persoanlities Social Network') %>%  
  visPhysics(stabilization = TRUE) %>%
  visOptions(highlightNearest=TRUE,
             nodesIdSelection=TRUE) %>% 
  visLegend(
    enabled = TRUE,
    addEdges = data.frame(
      label = c("Blood related and couple", "Close friend","relative","friend", "acquaintance"),
      color = c("darkred", "darkgreen", "pink", "lightgreen","darkgray")))%>% 
  visNodes(size = 5, color = list(highlight = "yellow"))


