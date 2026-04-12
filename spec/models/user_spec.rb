require "rails_helper"

RSpec.describe User, type: :model do
  let_it_be(:quarter) { create(:quarter, :current) }
  let_it_be(:unit_lead_user) { create(:unit_lead) }
  let_it_be(:unit) { create(:unit, unit_lead: unit_lead_user) }
  let_it_be(:team) { create(:team, unit: unit) }
  let_it_be(:other_team) { create(:team, unit: unit) }
  let_it_be(:engineer) { create(:engineer, team: team) }
  let_it_be(:team_lead_user) { create(:team_lead, team: team) }
  let_it_be(:other_team_lead) { create(:team_lead, team: other_team) }
  let_it_be(:technology) { create(:technology) }
  let_it_be(:admin) { create(:admin) }

  describe ".pending_approvals_count" do
    it "returns 0 for engineer" do
      expect(described_class.pending_approvals_count(engineer)).to eq(0)
    end

    it "returns 0 when no submitted ratings" do
      expect(described_class.pending_approvals_count(team_lead_user)).to eq(0)
    end

    context "for team lead" do
      it "counts engineers with submitted ratings in own team" do
        create(:skill_rating, :submitted, user: engineer, technology: technology, quarter: quarter, team: team)

        expect(described_class.pending_approvals_count(team_lead_user)).to eq(1)
      end

      it "ignores other teams" do
        other_engineer = create(:engineer, team: other_team)
        create(:skill_rating, :submitted, user: other_engineer, technology: technology, quarter: quarter, team: other_team)

        expect(described_class.pending_approvals_count(team_lead_user)).to eq(0)
      end
    end

    context "for unit lead" do
      it "counts team leads with submitted ratings, not engineers" do
        create(:skill_rating, :submitted, user: engineer, technology: technology, quarter: quarter, team: team)
        create(:skill_rating, :submitted, user: team_lead_user, technology: technology, quarter: quarter, team: team)

        expect(described_class.pending_approvals_count(unit_lead_user)).to eq(1)
      end

      it "counts team leads across multiple teams in unit" do
        create(:skill_rating, :submitted, user: team_lead_user, technology: technology, quarter: quarter, team: team)
        create(:skill_rating, :submitted, user: other_team_lead, technology: technology, quarter: quarter, team: other_team)

        expect(described_class.pending_approvals_count(unit_lead_user)).to eq(2)
      end

      it "returns 0 when no submitted ratings from team leads" do
        create(:skill_rating, :submitted, user: engineer, technology: technology, quarter: quarter, team: team)

        expect(described_class.pending_approvals_count(unit_lead_user)).to eq(0)
      end
    end

    context "for admin" do
      it "counts all users with submitted ratings" do
        create(:skill_rating, :submitted, user: engineer, technology: technology, quarter: quarter, team: team)
        create(:skill_rating, :submitted, user: team_lead_user, technology: technology, quarter: quarter, team: team)

        expect(described_class.pending_approvals_count(admin)).to eq(2)
      end
    end

    it "counts distinct users not distinct ratings" do
      tech2 = create(:technology)
      create(:skill_rating, :submitted, user: engineer, technology: technology, quarter: quarter, team: team)
      create(:skill_rating, :submitted, user: engineer, technology: tech2, quarter: quarter, team: team)

      expect(described_class.pending_approvals_count(team_lead_user)).to eq(1)
    end

    it "returns 0 when nil approver" do
      expect(described_class.pending_approvals_count(nil)).to eq(0)
    end
  end

  describe ".users_with_pending_approvals" do
    it "returns empty relation for engineer" do
      expect(described_class.users_with_pending_approvals(engineer)).to eq([])
    end

    context "for team lead" do
      it "returns engineers with submitted ratings in own team" do
        create(:skill_rating, :submitted, user: engineer, technology: technology, quarter: quarter, team: team)

        result = described_class.users_with_pending_approvals(team_lead_user)
        expect(result).to include(engineer)
      end

      it "does not include engineers from other teams" do
        other_engineer = create(:engineer, team: other_team)
        create(:skill_rating, :submitted, user: other_engineer, technology: technology, quarter: quarter, team: other_team)

        result = described_class.users_with_pending_approvals(team_lead_user)
        expect(result).not_to include(other_engineer)
      end
    end

    context "for unit lead" do
      it "returns only team leads, not engineers" do
        create(:skill_rating, :submitted, user: engineer, technology: technology, quarter: quarter, team: team)
        create(:skill_rating, :submitted, user: team_lead_user, technology: technology, quarter: quarter, team: team)

        result = described_class.users_with_pending_approvals(unit_lead_user)
        expect(result).to include(team_lead_user)
        expect(result).not_to include(engineer)
      end
    end

    context "for admin" do
      it "returns all users with submitted ratings" do
        create(:skill_rating, :submitted, user: engineer, technology: technology, quarter: quarter, team: team)
        create(:skill_rating, :submitted, user: team_lead_user, technology: technology, quarter: quarter, team: team)

        result = described_class.users_with_pending_approvals(admin)
        expect(result).to contain_exactly(engineer, team_lead_user)
      end
    end

    describe ".from_omniauth" do
      let(:auth_hash) do
        OmniAuth::AuthHash.new(
          provider: "oidc",
          uid: "12345",
          info: {
            email: "oidc@example.com",
            first_name: "OIDC",
            last_name: "User",
            name: "OIDC User"
          },
          credentials: {
            id_token: "test-id-token"
          }
        )
      end

      it "finds existing user by provider and uid" do
        user = create(:user, provider: "oidc", uid: "12345", email: "oidc@example.com")

        result = described_class.from_omniauth(auth_hash)
        expect(result).to eq(user)
      end

      it "finds existing user by email and links provider" do
        user = create(:user, email: "oidc@example.com", provider: nil, uid: nil)

        result = described_class.from_omniauth(auth_hash)
        expect(result).to eq(user)
        expect(result.provider).to eq("oidc")
        expect(result.uid).to eq("12345")
      end

      it "creates new user with engineer role when no match" do
        result = described_class.from_omniauth(auth_hash)

        expect(result).to be_persisted
        expect(result.email).to eq("oidc@example.com")
        expect(result.provider).to eq("oidc")
        expect(result.uid).to eq("12345")
        expect(result.role).to eq("engineer")
        expect(result.active).to be(true)
      end

      it "raises when email is blank" do
        blank_auth = OmniAuth::AuthHash.new(
          provider: "oidc",
          uid: "12345",
          info: {email: nil},
          credentials: {}
        )

        expect { described_class.from_omniauth(blank_auth) }
          .to raise_error("OIDC provider did not return email")
      end
    end
  end
end
