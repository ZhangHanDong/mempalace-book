# MemPalace：AI 记忆的第一性原理

**副标题**：当对话成为决策的载体，记忆系统该如何设计

**类型**：技术 + 产品（非教程）

**语言**：中文

---

## 前言：一个演员、一个比特币工程师、和一个 AI

- Ben Sigman 的宣言（原文引用）
- Milla Jovovich — 好莱坞演员如何成为 AI 记忆系统的 architect
- Ben Sigman — UCLA 古典学 + 20 年系统工程 + Bitcoin Libre CEO
- Claude 作为第三个合作者
- 项目发布时间线与早期反响（2200+ stars, Brian Roemmele 部署 79 人）
- 为什么写这本书

---

## 第一部分：问题空间

### 第 1 章：对话即决策
- 决策从 Jira/Confluence 迁移到 AI 对话
- 6 个月 = 1950 万 token 蒸发
- 知识管理范式断裂

### 第 2 章：摘要陷阱
- Mem0/Zep/Letta 的核心假设：让 LLM 决定什么值得记住
- 为什么这是根本性错误
- benchmark 数据量化损失

### 第 3 章：逐字存储的经济学
- 全量粘贴 vs 摘要 vs MemPalace 唤醒
- 存储廉价，检索才是难题

---

## 第二部分：记忆宫殿——一个两千年前的数据结构

### 第 4 章：Method of Loci
- 西蒙尼德斯的宴会厅故事
- 认知科学验证
- 空间结构对检索的有效性
- Ben 的古典学背景与方法论连接

### 第 5 章：Wing / Hall / Room / Closet / Drawer
- 每一层的设计动机
- Wing 是语义边界，Hall 是认知分类，Room 是概念节点
- 为什么 Hall 固定 5 种而不是自定义
- 源码：palace_graph.py, searcher.py

### 第 6 章：隧道——跨领域发现
- Tunnel 跨 wing 连接
- BFS 图遍历
- 从 ChromaDB 元数据零成本构建图
- 源码：palace_graph.py

### 第 7 章：34% 的检索提升不是巧合
- 控制实验数据：60.9% → 94.8%
- 语义相似性在大规模语料中退化
- 结构约束充当先验知识

---

## 第三部分：AAAK——为 AI 设计的语言

### 第 8 章：压缩的约束空间
- 需求：30x 压缩、零信息损失、任何模型可读、无需解码器
- 排除方案分析
- 必须是"极度缩写的英语"

### 第 9 章：AAAK 的语法设计
- 3 字母编码、管道分隔、箭头因果、星级重要性
- 源码：dialect.py
- 模型第一次看到 spec 就能读写

### 第 10 章：跨模型通用性
- Claude/GPT/Gemini/Llama/Mistral 都能理解
- 记忆系统与模型供应商解耦
- 整个栈可完全离线

---

## 第四部分：时间维度——事实会过期

### 第 11 章：时态知识图谱
- 静态 KG vs 时态 KG
- valid_from / valid_to 设计
- SQLite vs Neo4j 的选择
- 源码：knowledge_graph.py

### 第 12 章：矛盾检测
- 动态计算任期、日期、归属
- 知识图谱实时查询
- 误报/漏报权衡

### 第 13 章：时间线叙事
- kg.timeline() 的转换逻辑
- 从离散三元组到编年史
- 新人 onboarding 场景

---

## 第五部分：四层记忆栈

### 第 14 章：L0-L3 的分层设计
- 每层内容、大小、加载时机、设计动机
- 为什么是 4 层
- token 预算确定方法
- 源码：layers.py

### 第 15 章：混合检索——从 96.6% 到 100%
- 纯 ChromaDB vs 混合模式
- 3.4% 失败案例分析
- 向量距离到语义理解的跃迁
- 源码：searcher.py

---

## 第六部分：数据摄入管道

### 第 16 章：格式归一化
- 5 种聊天格式结构差异
- 自动检测与 fallback
- 源码：normalize.py

### 第 17 章：无 ML 的实体发现
- 人物/项目检测的规则方法
- 候选评分与交互确认
- 为什么不用 NER
- 源码：entity_detector.py, entity_registry.py

### 第 18 章：分块的学问
- 项目文件 vs 对话的不同策略
- 问答对是最小语义单元
- 源码：miner.py, convo_miner.py

---

## 第七部分：接口设计

### 第 19 章：MCP 服务器——19 个工具的 API 设计
- 读/写/导航/知识图谱/日记的划分逻辑
- mempalace_status 的核心地位
- 源码：mcp_server.py

### 第 20 章：专家代理系统
- 每个 agent 一个 wing + 日记
- AAAK 日记格式
- 与 Letta 对比
- 50 agent 不膨胀的秘密

### 第 21 章：本地模型集成
- wake-up 输出 170 token
- Python API 按需查询
- 整个栈离线运行

---

## 第八部分：验证

### 第 22 章：Benchmark 方法论
- LongMemEval/LoCoMo/ConvoMem 选择原因
- 每个 benchmark 的能力与盲区
- 可复现性

### 第 23 章：竞品对比的诚实分析
- MemPalace vs Mem0/Zep/Letta/Supermemory
- 赢在哪里、输在哪里
- LoCoMo 60.3% 的坦诚分析

---

## 第九部分：设计哲学与未来

### 第 24 章：本地优先不是妥协
- 隐私是架构约束
- Ben 的去中心化背景（Bitcoin Libre）
- MIT 开源的意义

### 第 25 章：超越对话
- 宫殿结构可适配任何数据
- AAAK 进入 Closet 层的技术路线
- 开源社区的探索方向

---

## 附录

### 附录 A：E2E Trace — 从 `mempalace init` 到第一次搜索
### 附录 B：E2E Trace — MCP 工具调用的完整生命周期
### 附录 C：AAAK 语法完整参考
### 附录 D：Benchmark 原始数据与复现指南

---

## 元信息

- 总章数：25 章 + 前言 + 第 0 章 + 4 个附录
- 每章模式：问题 → 设计决策 → 权衡分析 → 源码实现 → 数据验证
- 源码基线：MemPalace v3.0.0
- 主要源码目录：/Users/zhangalex/Work/Projects/AI/mempalace/mempalace/
