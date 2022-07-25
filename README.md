# ‘GWR.multicollin.diagno’: a Function to Address Multicollinearity in Geographically Weighted Regression Models

## Introduction and rationale

Geographically weighted models are designed to handle non-stationary spatial data, whose properties vary across the study area. Geographically weighted regression explores spatially- varying relationships between dependent and independent variables, and aims at finding spatial heterogeneities is these relationships. It uses a kernel function to calculate weights applied in a series of local linear regression models across the study area. A common form of data visualization that follows is a map of local GWR coefficients associated with each explanatory variable.

The function presented in this paper addresses a limitation of geographically weighted regression, multicollinearity. Collinearity between independent variables, even moderate, can lead to strong dependence in local estimated coefficients which, in turn, can weaken or even invalidate interpretation of local coefficients. Multicollinearity can be identified at two levels. On the one hand, codependent predictor variables cause correlations between overall sets of local coefficients. On the other hand, pairs of local regression coefficients can be correlated at one specific location. When controlling GWR, it is crucial to assess multicollinearity at both levels; indeed, local coefficients may be collinear even in the absence of significant global correlation between the independent variables underlying the GWR model (Wheeler & Tiefelsdorf, 2005, 163).

