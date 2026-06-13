package model

import "time"

// 本文件提供补充的辅助结构体：
// - 分页请求响应
// - 通用实体引用
// - 时间线条目
//
// 核心数据库模型已经在 model.go 中通过 type alias 暴露，
// 因此本文件不再重复定义。

type PageRequest struct {
	Page     int `form:"page" json:"page"`
	PageSize int `form:"page_size" json:"page_size"`
}

func (p *PageRequest) Offset() int {
	if p.Page <= 0 {
		p.Page = 1
	}
	if p.PageSize <= 0 || p.PageSize > 500 {
		p.PageSize = 20
	}
	return (p.Page - 1) * p.PageSize
}

func (p *PageRequest) Limit() int {
	return p.Offset() + p.PageSize
}

type PageResponse struct {
	Total    int         `json:"total"`
	Page     int         `json:"page"`
	PageSize int         `json:"page_size"`
	Data     interface{} `json:"data"`
}

type EntityRef struct {
	ID   uint   `json:"id"`
	Name string `json:"name"`
}

type TimelineItem struct {
	ID      uint      `json:"id"`
	Title   string    `json:"title"`
	Content string    `json:"content"`
	Time    time.Time `json:"time"`
	Type    string    `json:"type"`
}
