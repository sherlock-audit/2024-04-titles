# TITLES Protocol v2

[**TITLES**](https://titles.xyz) is an AI-powered creative tool for remixing, creating, and publishing referential cryptomedia. NFTs published through TITLES can sample other NFTs, maintaining attribution and splitting proceeds with sampled NFTs’ creators.

## Protocol Overview

The TITLES protocol consists of:

- **TitlesCore** is the core protocol entrypoint which manages the creation and distribution of TITLES Editions. 
- **TitlesGraph** is an on-chain graph that represents the relationships between TITLES Editions and the individual works that have been sampled by or otherwise contributed to a given Edition. It is the first reference implementation for the upcoming OpenGraph Standard.
- **FeeManager**: The module responsible for calculating and collecting fees throughout the TITLES protocol, then routing them to their respective targets. It is powered by the Splits protocol, which provides a simple mechanism for distributing assets to multiple recipients.
- **Editions** are ERC1155 contracts in which each token ID represents an individual work that has been published through the TITLES protocol. Editions can be created by anyone, and can include any number of works. Edition creators can also enable others to contribute works to their Editions, allowing for collaborative creation and curation. There are no assumptions about the nature of the works that can be included in an Edition, which opens up a wide range of creative possibilities.

Each work (i.e. unique token ID) in an **Edition** is associated with a **Node** within the TITLES Graph. Through this graph, the relationships between works can be visualized and navigated, allowing users to explore the provenance of a given work and the various works that have contributed to its creation. The OpenGraph Standard aims to provide a generalized framework for identifying referential relationships between works, enabling a new class of creative tools and experiences.
