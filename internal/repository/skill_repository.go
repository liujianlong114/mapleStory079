package repository

import (
	"mapleStory079/pkg/database"
)

// SkillRepository 技能数据访问层
type SkillRepository struct{}

// NewSkillRepository 创建技能仓库
func NewSkillRepository() *SkillRepository {
	return &SkillRepository{}
}

// GetByID 根据 ID 获取技能
func (r *SkillRepository) GetByID(id uint) (*database.Skill, error) {
	var skill database.Skill
	if err := database.DB.First(&skill, id).Error; err != nil {
		return nil, err
	}
	return &skill, nil
}

// GetAll 获取所有技能
func (r *SkillRepository) GetAll() ([]database.Skill, error) {
	var skills []database.Skill
	if err := database.DB.Find(&skills).Error; err != nil {
		return nil, err
	}
	return skills, nil
}

// GetByJob 根据职业筛选技能
func (r *SkillRepository) GetByJob(jobClass int) ([]database.Skill, error) {
	var skills []database.Skill
	if err := database.DB.Where("job_class = ?", jobClass).Find(&skills).Error; err != nil {
		return nil, err
	}
	return skills, nil
}

// Create 创建技能
func (r *SkillRepository) Create(skill *database.Skill) error {
	return database.DB.Create(skill).Error
}

// Update 更新技能
func (r *SkillRepository) Update(skill *database.Skill) error {
	return database.DB.Save(skill).Error
}

// Delete 删除技能
func (r *SkillRepository) Delete(id uint) error {
	return database.DB.Delete(&database.Skill{}, id).Error
}
