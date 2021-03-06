library(SNFtool)
library(igraph)
library(ggplot2)
library(cluster)
library(vegan)

data_clinical <- read.csv("data_clinical.csv",row.names = 1)

data_gene_expr <- read.csv("data_mRNA_processed.csv",row.names = 1)
patient_samples_gdata <- colnames(data_gene_expr)

data_methyl <- read.csv("data_methyl_processed.csv",row.names = 1)
data_methyl$Entrez_Gene_Id <- NULL
patient_samples_mdata <- colnames(data_methyl)

patients <- intersect(patient_samples_gdata,patient_samples_mdata)

df_cmn_gene_expr <- t(data_gene_expr[,patients])
df_cmn_meth <- t(data_methyl[,patients])

dist_gene <- as.matrix(dist(df_cmn_gene_expr))
dist_meth <- as.matrix(dist(df_cmn_meth))

W1 <- affinityMatrix(dist_gene,15)
W2 <- affinityMatrix(dist_meth,15)

PC <- SNF(list(W1,W2),15,20)

g <- graph.adjacency(PC,mode = "undirected", weighted = TRUE)
sgc <- spinglass.community(g)
par(mar=rep(0,4))
glayout <- layout.fruchterman.reingold(g,
  minx=rep(-200,58),miny=rep(-200,58),maxx=rep(200,58),maxy=rep(200,58),niter=1500)
plot(g,layout = glayout,vertex.color = sgc$membership, vertex.size = 8)

months_data <- data.frame(Cluster = as.character(),OS_MONTHS = as.numeric(), DFS_MONTHS = as.numeric())
for(i in 1:length(unique(sgc$membership))){
  group_data <- data_clinical[patients[sgc$membership == i],c('OS_MONTHS','DFS_MONTHS')]
  months_data <- rbind(months_data,cbind(Cluster = i,group_data))  
}

p <- ggplot(months_data, aes(x=as.factor(Cluster), y=OS_MONTHS, fill=as.factor(Cluster))) +
  geom_violin(trim=FALSE)
p + xlab("Clusters") + ylab("OS Months") + labs(fill='Clusters') 

p <- ggplot(months_data, aes(x=as.factor(Cluster), y=DFS_MONTHS, fill=as.factor(Cluster))) +
  geom_violin(trim=FALSE)
p + xlab("Clusters") + ylab("DFS Months") + labs(fill='Clusters') 